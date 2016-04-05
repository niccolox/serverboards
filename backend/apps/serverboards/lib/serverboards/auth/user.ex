require Logger

defmodule Serverboards.Auth.User do
	use Ecto.Schema
	import Ecto.Changeset
	import Ecto.Query

	alias Serverboards.Auth.User
	alias Serverboards.Repo

	schema "auth_user" do
			field :email, :string
			field :first_name, :string
			field :last_name, :string
			field :is_active, :boolean
			timestamps
	 end

	 @required_fields ~w(email first_name)
	 @optional_fields ~w()

	 @doc ~S"""
	 Gets an user by email, and updates permissions. Its for other auth modes,
	 as token, or external.
	 """
	 def get_user(email) do
		user=case Repo.get_by(User, email: email, is_active: true) do
 			{:error, _} -> nil
 			user -> user
 		end
		if user do
			User.to_map user
		else
			Logger.warn("Try to get non existent user by email: #{email}")
			false
		end
	 end

	 def to_map(user) do
		 %{
			 id: user.id,
			 email: user.email,
			 first_name: user.first_name,
			 last_name: user.last_name,
			 perms: get_perms(user)
		 }
	 end

	 @doc ~S"""
	 Gets all permissions for this user
	 """
	 def get_perms(user) do
		alias Serverboards.Auth.{Permission, GroupPerms, UserGroup}
		alias Serverboards.Repo

		Repo.all(
			from p in Permission,
				join: gp in GroupPerms,
					on: gp.perm_id == p.id,
				join: ug in UserGroup,
					on: ug.group_id == gp.group_id,
			 where: ug.user_id == ^user.id,
			select: p.code
		)
	end

	@doc ~S"""
	Prepares changeset ensuring required data is there, proper
	password lenth, and hashes the password.
	"""
	def changeset(user, params \\ :empty) do
		import Ecto.Changeset
		user
			|> cast(params, [:email], [:is_active, :first_name, :last_name])
			|> unique_constraint(:email)
	end
end
