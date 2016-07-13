require Logger

defmodule Serverboards.Auth do
	@moduledoc ~S"""
	Manages authentication of users.

	It can use custom auth methods (`add_auth`) in elixir code, or plugins,
	which is any component with the `auth` trait.

	## Example

		iex> auth %{ "type" => "invalid" }
		false

	Create new auths:

		iex> add_auth "letmein", fn %{ "email" => email } -> email end
		iex> auth %{ "type" => "letmein", "email" => "dmoreno@serverboards.io" }
		"dmoreno@serverboards.io"

	Using the fake auth plugin:

		iex> auth %{ "type" => "fake", "token" => "XXX" }
		{:ok, "dmoreno@serverboards.io"}
		iex> auth %{ "type" => "fake", "token" => "xxx" }
		{:ok, false}

	"""
	use GenServer

	alias MOM.RPC

	defstruct []

	def start_link(_,_) do
		{:ok, pid} = GenServer.start_link __MODULE__, :ok, name: Serverboards.Auth

		add_auth "basic", fn params ->
			#Logger.debug("Try to log in #{inspect params}")
			%{ "type" => "basic", "email" => email, "password" => password} = params

			case Serverboards.Auth.User.Password.auth(email, password) do
				{:error, _} -> false
				false -> false
				user -> user
					#%{ email: user.email, permissions: user.perms, first_name: user.first_name, last_name: user.last_name }
			end
		end

		add_auth "token", fn params ->
			Logger.debug("Try to log in #{inspect params}")
			%{ "type" => "token", "token" => token} = params

			case Serverboards.Auth.User.Token.auth(token) do
				{:error, _} -> false
				false -> false
				user -> user
					#%{ email: user.email, permissions: user.perms, first_name: user.first_name, last_name: user.last_name }
			end
		end

		#Logger.debug("Auth server ready.")

		{:ok, pid}
	end

	@doc ~S"""
	Check is gien params allow for login.

	Params must contain `type`.

	Returns:
		* false -- no login
		* email -- Uses that email to get all the permissions and data from database

	"""
	def auth(%{ "type" => _ } = params) do
		GenServer.call(Serverboards.Auth, {:auth, params})
	end

	def client_set_user(client, user) do
		Logger.debug("Setting user: #{inspect user}")
		RPC.Client.set client, :user, user
		MOM.Channel.send(:auth_authenticated, %MOM.Message{ payload: %{ client: client, user: user } }, [sync: true])
	end

	@doc ~S"""
	Sets up the client for authentication.

	Can call a continuation function f(user) when authentication succeds.
	"""
	def authenticate(client, cont \\ nil) do
		#Logger.debug("Asking for authentication #{inspect client}")

		RPC.Client.add_method(client, "auth.auth", fn
			%{ "type" => _ } = params ->
				user = auth(params)
				if user do
					#remove_method(method_id)
					#Logger.debug("Logged in!")
					client_set_user(client, user)

					if cont do
						cont.(user)
					end
					user
				else
					#Logger.debug("NOT Logged in.")
					false
				end
		end)
		RPC.Client.add_method(client, "auth.reset_password", fn
			[email] -> # Request token
				Logger.debug("Reset password for #{email}")
				# Check user exists, and is active
				case Serverboards.Auth.User.user_info(email, [require_active: true], %{email: email}) do
					false ->
						Logger.error("Denied password reset link requested for #{email}")
						{:error, :not_allowed}
					me ->
						Logger.info("Password reset link requested for #{email}")
						token = Serverboards.Auth.User.Token.create(me, ["auth.reset_password"])
						link="http://localhost:3000/##{token}"
						Serverboards.Notifications.notify(
							email,
							"Password reset link",
							"Please click on the following link to reset your password.\n\n#{link}",
							[], me
							)
						{:ok, :ok}
				end
			[email, token, new_password] -> # Reset password
				case Serverboards.Auth.User.Token.auth(token) do
					false -> {:error, :not_allowed}
					user ->
						if "auth.reset_password" in user.perms and user.email==email do
							:ok = Serverboards.Auth.User.Password.password_set(user, new_password, user)
							:ok = Serverboards.Auth.User.Token.invaldate(token)
							{:ok, :ok}
						else
							{:error, :not_allowed}
						end
				end
				{:ok, :ok}
		end)

		RPC.Client.event( client, "auth.required", list_auth )
		:ok
	end

	def reauthenticate(client) do
		GenServer.call(Serverboards.Auth, {:reauth, client})
	end

	def add_auth(type, f) do
		GenServer.call(Serverboards.Auth, {:add_auth, type, f})
	end

	@doc ~S"""
	Returns the list of known authentications

		iex> l = list_auth
		iex> (Enum.count l) >= 1
		true
		iex> "basic" in l
		true
	"""
	def list_auth do
		GenServer.call(Serverboards.Auth, {:list_auth})
	end

	## server impl
	def init(:ok) do
		{:ok, es } = EventSourcing.start_link name: :auth
		{:ok, _rpc} = Serverboards.Auth.RPC.start_link

		EventSourcing.Model.subscribe es, :auth, Serverboards.Repo
    EventSourcing.subscribe es, :debug_full

		Serverboards.Auth.User.setup_eventsourcing(es)
		Serverboards.Auth.Group.setup_eventsourcing(es)

		{:ok, %{
			auths: %{}
		} }
	end


	def handle_call({:auth, params}, _, state) do
		type = Map.get(params, "type")
		auth_f = Map.get(state.auths, type)

		user = if auth_f do
			try do
				auth_f.(params)
			rescue
				e ->
					Logger.error("Error at auth \"#{type}\":\n #{inspect e}\n #{Exception.format_stacktrace System.stacktrace}")
					false
			end
		else
			case Serverboards.Plugin.Registry.filter_component trait: "auth", id: type do
				[] ->
					Logger.error("Unknown auth #{type}")
					false
				[component] ->
					case Serverboards.Plugin.Runner.start component do
						{:ok, cmd} ->
							res = case Serverboards.Plugin.Runner.call cmd, "auth", params do
								{:error, _} ->
									false
								res ->
									res
							end
							Serverboards.Plugin.Runner.stop cmd
							res
						_ ->
							false
					end
			end
		end
		#Logger.debug("Auth result #{inspect auth}")


		if user do
			Logger.info("Logged in #{inspect user}")
			{:reply, user, state}
		else
			{:reply, false, state}
		end

	end

	def handle_call({:add_auth, name, f}, _, state) do
		{:reply, :ok,
			%{ state | auths: Map.put(state.auths, name, f) }
		}
	end

	def handle_call({:list_auth}, _, state) do
		{:reply, list_auth_(state), state}
	end

	# This is a server side call, to avoid deadlock
	defp list_auth_(state) do
		Map.keys(state.auths)
	end

	def handle_call({:reauth, client}, from, state) do
		Logger.debug("client #{inspect client}")
		RPC.Client.cast( client, "auth.reauth", list_auth_(state), fn res ->
			Logger.info("Auth required answer: #{inspect res}")
			GenServer.reply(from, res)
		end )

		{:noreply, state}
	end
end
