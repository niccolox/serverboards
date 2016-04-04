require Logger

defmodule Serverboards.Auth.User.Password do
	use Ecto.Schema
	alias Serverboards.Auth.User
	alias User.Password
	alias Serverboards.Auth.Repo

	schema "auth_user_password" do
		field :password, :string
		belongs_to :user, User

		timestamps
	end

	@doc ~S"""
	Sets the given password for that user struct.
	"""
	def set_password(user, password) do
		case Repo.get_by(User.Password, user_id: user.id) do
			nil ->
				Repo.insert(changeset(%User.Password{}, %{
					user_id: user.id,
					password: password
					} ) )
			pw ->
				Repo.update(changeset(pw, %{ password: password }))
		end
	end

	@doc ~S"""
	Geiven an user (with user.id) and a password hash, checks it.

	Returns error on any error, as user has no password, or invalid
	password.

	In case of fail (no valid user, no valid hash), it performs a
	dummy check, just to take some time and processing.
	"""
	def check_password(user, password) do
		import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
		case Repo.get_by(Password, user_id: user.id) do
			{:error, _} ->

				dummy_checkpw
			pw ->
				case pw.password do
					"$bcrypt$" <> hash ->
							checkpw(password, hash)
						_ ->
							dummy_checkpw
				end
		end
	end

	# modifier to ecrypt passwords properly.
	defp bcrypt_password(password) do
		import Comeonin.Bcrypt, only: [hashpwsalt: 1]
			hash=hashpwsalt(password)
			"$bcrypt$#{hash}"
	end

	@doc ~S"""
	Prepares changeset ensuring required data is there, proper
	password lenth, and hashes the password.
	"""
	def changeset(password, params \\ :empty) do
		import Ecto.Changeset
		#Logger.debug("orig #{inspect password}, new #{inspect params}")
		password
			|> cast(params, [:password, :user_id], ~w())
			|> validate_length(:password, min: 8)
			|> put_change(:password, bcrypt_password(params[:password]))
	end
end
