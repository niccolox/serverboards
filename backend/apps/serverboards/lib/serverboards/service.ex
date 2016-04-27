require Logger

defmodule Serverboards.Service do
  import Ecto.Changeset
  import Ecto.Query

  alias Serverboards.MOM.RPC
  alias Serverboards.MOM.RPC.Context
  alias Serverboards.MOM
  alias Serverboards.Repo
  alias Serverboards.Service

  def start_link(options \\ []) do
    {:ok, mc} = RPC.MethodCaller.start_link options

    # Adds that it needs permissions.
    Serverboards.Utils.Decorators.permission_method_caller mc

    RPC.MethodCaller.add_method mc, "service.add", fn [servicename, options], context ->
      #Logger.debug("#{inspect Context.debug(context)}")
      {:ok, service} = service_add servicename, options, Context.get(context, :user)
      {:ok, Serverboards.Utils.clean_struct service}
    end, [requires_perm: "service.add", context: true]

    RPC.MethodCaller.add_method mc, "service.update", fn
      [service_id, operations], context ->
        {:ok, service} = service_update service_id, operations, Context.get(context, :user)
        {:ok, Serverboards.Utils.clean_struct service}
    end, [requires_perm: "service.add", context: true]

    RPC.MethodCaller.add_method mc, "service.delete", fn [service_id], context ->
      service_delete service_id, Context.get(context, :user)
    end, [requires_perm: "service.add", context: true]

    RPC.MethodCaller.add_method mc, "service.info", fn [service_id], context ->
      {:ok, service} = service_info service_id, Context.get(context, :user)
      {:ok, Serverboards.Utils.clean_struct service}
    end, [requires_perm: "service.add", context: true]

    RPC.MethodCaller.add_method mc, "service.list", fn [], context ->
      Logger.info("Service List!!!")
      {:ok, services} = service_list Context.get(context, :user)
      Enum.map services, &Serverboards.Utils.clean_struct(&1)
    end, [requires_perm: "service.list", context: true]

    # All authenticated users may use this method caller, but it ensures permissions before any call.
    MOM.Channel.subscribe(:auth_authenticated, fn %{ payload: %{ client: client, user: user}} ->
      RPC.add_method_caller (RPC.Client.get client, :to_serverboards), mc
      :ok
    end)

    {:ok, mc}
  end

  @doc ~S"""
  Creates a new service given the shortname, attributes and creator_id

  Attributes is a Map with the service attributes (strings, not atoms) All are optional.

  Attributes:
  * name -- Service name
  * description -- Long description
  * priority -- Used for sorting, increasing.
  * tags -- List of tags to apply.

  ## Example

    iex> user = Serverboards.Auth.User.get_user("dmoreno@serverboards.io")
    iex> {:ok, service} = service_add "SBDS-TST1", %{ "name" => "serverboards" }, user
    iex> {:ok, info} = service_info service.id, user
    iex> info.name
    "serverboards"
    iex> service_delete "SBDS-TST1", user
    :ok

  """
  def service_add(shortname, attributes, me) do
    Repo.insert( Service.Service.changeset(%Service.Service{}, %{
      shortname: shortname,
      creator_id: me.id,
      name: Map.get(attributes,"name", shortname),
      description: Map.get(attributes, "description", ""),
      priority: Map.get(attributes, "priority", 50),
      } ) )
  end

  @doc ~S"""
  Updates a service by id or shortname

  ## Example:

    iex> user = Serverboards.Auth.User.get_user("dmoreno@serverboards.io")
    iex> {:ok, service} = service_add "SBDS-TST2", %{ "name" => "serverboards" }, user
    iex> {:ok, service} = service_update service.id, %{ "name" => "Serverboards" }, user
    iex> {:ok, info} = service_info service.id, user
    iex> info.name
    "Serverboards"
    iex> service_delete "SBDS-TST2", user
    :ok

  """
  def service_update(service, operations, me) when is_map(service) do
    import Ecto.Query, only: [from: 2]
    Logger.debug("service_update #{inspect {service.shortname, operations, me}}, service id #{service.id}")

    # update tags
    tags = MapSet.new Map.get(operations, "tags", [])
    current_tags = MapSet.new Repo.all(Service.ServiceTag, service_id: service.id), fn t -> t.name end
    new_tags = MapSet.difference(tags, current_tags)
    expired_tags = MapSet.difference(current_tags, tags)

    Logger.debug("Update service tags. Add #{inspect new_tags}, remove #{inspect expired_tags}")

    if (Enum.count expired_tags) > 0 do
      expired_tags = MapSet.to_list expired_tags
      Repo.delete_all( from t in Service.ServiceTag, where: t.service_id == ^service.id and t.name in ^expired_tags )
    end
    Enum.map(new_tags, fn name ->
      Repo.insert(%Service.ServiceTag{name: name, service_id: service.id} )
    end)

    # changes on service itself.
    changes = Enum.reduce(operations, %{}, fn op, acc ->
      Logger.debug("#{inspect op}")
      {opname, newval} = op
      opatom = case opname do
        "name" -> :name
        "description" -> :description
        "priority" -> :priority
        "tags" -> nil
        e ->
          Logger.error("Unknown operation #{inspect e}. Failing.")
          raise Exception, "Unknown operation updating service #{service.shortname}: #{inspect e}. Failing."
        end
        if opatom do
          Map.put acc, opatom, newval
        else
          acc
        end
      end)

    {:ok, upd} = Repo.update( Service.Service.changeset(
    service,
    changes
    ) )
    {:ok, upd}
  end
  def service_update(service_id, operations, me) when is_number(service_id) do
    service_update(Repo.get_by(Service.Service, [id: service_id]), operations, me)
  end
  def service_update(servicename, operations, me) when is_binary(servicename) do
    service_update(Repo.get_by(Service.Service, [shortname: servicename]), operations, me)
  end

  @doc ~S"""
  Deletes a service by id or name
  """
  def service_delete(service_id, _me) when is_number(service_id) do
    Repo.delete( Repo.get_by(Service.Service, [id: service_id]) )
  end
  def service_delete(service_shortname, _me) when is_binary(service_shortname) do
    Repo.delete( Repo.get_by(Service.Service, [shortname: service_shortname]) )
    :ok
  end

  @doc ~S"""
  Returns the information of a service by id or name
  """
  def service_info(service_id, _me) when is_number(service_id) do
    case Repo.one( from( s in Service.Service, where: s.id == ^service_id, preload: :tags ) ) do
      nil -> {:error, :not_found}
      service ->
        service = %{ service | tags: Enum.map(service.tags, fn t -> t.name end)}
        {:ok, service }
    end
  end
  def service_info(service_shortname, _me) when is_binary(service_shortname) do
    case Repo.one( from(s in Service.Service, where: s.shortname == ^service_shortname, preload: :tags ) ) do
      nil -> {:error, :not_found}
      service ->
        service = %{ service | tags: Enum.map(service.tags, fn t -> t.name end)}
        {:ok, service }
    end
  end

  @doc ~S"""
  Returns a list with all services and its information

  ## Example

    iex> require Logger
    iex> user = Serverboards.Auth.User.get_user("dmoreno@serverboards.io")
    iex> {:ok, l} = service_list user.id
    iex> is_list(l) # may be empty or has something from before, but lists
    true
    iex> {:ok, _service} = service_add "SBDS-TST4", %{ "name" => "serverboards" }, user
    iex> {:ok, l} = service_list user.id
    iex> Logger.debug(inspect l)
    iex> Enum.any? l, &(&1["shortname"]=="SBDS-TST4") # exists in the list?
    true
    iex> service_delete "SBDS-TST4", user
    :ok

  """
  def service_list(_me) do
    {:ok, Enum.map(Serverboards.Repo.all(Serverboards.Service.Service), &Serverboards.Utils.clean_struct(&1)) }
  end

end
