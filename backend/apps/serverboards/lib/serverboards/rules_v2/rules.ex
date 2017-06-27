require Logger
alias Serverboards.Repo
alias Serverboards.RulesV2.Model

defmodule Serverboards.RulesV2.Rules do
  @moduledoc ~S"""
  Rules are specified in a tree like structure, that un yaml is represented for
  example as:

  ```yaml
  name: Rule
  description: My description
  rule:
    trigger:
      - id: A
        type: trigger
        trigger: serverboards.core.ssh/remote_exec
        params:
          - command: grep "error" /var/log/mail.log
            period: 5m
            service_id: [UUID]
    actions:
      - id: B
        type: condition
        condition: A.exit_code == 0 and prev.A.exit_code == 1
        then:
          - id: C
            type: action
            action: serverboards.core.actions/notify
            params:
              - to: @user
                subject: No errors now
                body: There are no errors
        else: []
      - id: D
        type: condition
        condition: A.exit_code == 1 and prev.A.exit_code == 0
        then:
          - id: E
            type: action: serverboards.core.actions/notify
            params:
             - to: @user
               subject: Errors at the log
               body: Check it out ASAP
  ```

  """

  def start_ets_table() do
    :ets.new(:rules_rule_id_cache, [:set, :public, :named_table])
  end

  def start_eventsourcing(options \\ []) do
    {:ok, es} = EventSourcing.start_link( [name: Serverboards.RulesV2.EventSourcing] ++ options )
    EventSourcing.Model.subscribe es, :rules_v2, Serverboards.Repo

    EventSourcing.subscribe es, :create, fn %{ uuid: uuid, data: data }, me ->
      rule = create_real(uuid, data)
      Serverboards.Event.emit("rules_v2.created", %{ rule: rule }, ["rules.view"])
      project = get_project(uuid)
      if (project != nil) do
        Serverboards.Event.emit("rules_v2.created[#{project}]", %{ rule: rule }, ["rules.view"])
      end
    end

    EventSourcing.subscribe es, :update, fn %{ uuid: uuid, changes: changes }, me ->
      rule = update_real(uuid, changes)
      Serverboards.Event.emit("rules_v2.updated", %{ rule: rule }, ["rules.view"])
      project = get_project(uuid)
      if (project != nil) do
        Serverboards.Event.emit("rules_v2.updated[#{project}]", %{ rule: rule }, ["rules.view"])
      end
    end

    {:ok, es}
  end

  def create( %{} = data, me ) do
    uuid = UUID.uuid4
    EventSourcing.dispatch(
      Serverboards.RulesV2.EventSourcing,
      :create,
      %{ uuid: uuid, data: data },
      me.email )
    {:ok, uuid}
  end

  def create_real(uuid, %{} = data) do
    data = Serverboards.Utils.keys_to_atoms_from_list(data, ~w"name description rule is_active deleted")
    data = Map.put(data, :uuid, uuid)
    data = if data[:project] do
      Map.put( data, :project_id, get_project_id_by_shortname(data.project))
    else data end
    {:ok, rule} = Repo.insert( Model.Rule.changeset( %Model.Rule{}, data ) )
    {:ok, _} = Repo.insert( Model.RuleState.changeset( %Model.RuleState{}, %{ rule_id: rule.id, state: %{} } ) )
    rule
  end

  def update(uuid, changes, me) do
    EventSourcing.dispatch(
      Serverboards.RulesV2.EventSourcing,
      :update,
      %{ uuid: uuid, changes: changes },
      me.email )
    :ok
  end

  def update_real(uuid, %{} = data) do
    case get_rule_id(uuid) do
      nil ->
        Logger.error("Unknown rule #{inspect uuid}")
      rule_id ->
        rule = Repo.get_by( Model.Rule, id: rule_id )
        data = if data[:project] do
          Map.put( data, :project_id, get_project_id_by_shortname(data.project))
        else data end
        Repo.update( Model.Rule.changeset( rule, data) )
    end
    :ok
  end

  def set_state_real(uuid, state) when is_map(state) do
    import Ecto.Query
    # Logger.debug("Set state #{inspect uuid} #{inspect state}")
    case get_rule_id( uuid ) do
      nil ->
        Logger.error("Unknown rule to set state to #{inspect uuid}", rule_id: uuid)
        {:error, :unknown_rule}
      rule_id ->
        # Logger.info("Updating rule id #{rule_id}", rule_id: uuid)
        Repo.update_all((
          from r in Model.RuleState,
          where: r.rule_id == ^rule_id,
          update: [set: [state: ^state, updated_at: fragment("NOW()")]]
        ),[])
      :ok
    end
  end
  def delete_real(uuid) do
    update_real(uuid, %{ deleted: true })
    :ok
  end

  def get_rule_id(uuid) when is_binary(uuid) do
    import Ecto.Query

    case :ets.lookup(:rules_rule_id_cache, uuid) do
      [] ->
        id = Repo.one( from r in Model.Rule, where: r.uuid == ^uuid, select: r.id )
        if id do
          :ets.insert(:rules_rule_id_cache, {uuid, id})
        end
        id
      [{^uuid, id}] ->
        id
    end
  end

  def decorate(rule) do
    project = get_project(rule.uuid)
    rule
      |> Map.drop([:__meta__, :project_id])
      |> Map.put(:project, project)
  end

  def list(filter \\ %{}) when is_map(filter) do
    import Ecto.Query
    q = (
      from r in Model.Rule,
      select: r
    )

    # By default show not deleted, may show only deleted, or both.
    q = case Map.get(filter, :deleted, false) do
      true ->
        where(q, [rule], rule.deleted)
      false ->
        where(q, [rule], not rule.deleted)
      :both ->
        q
    end

    q = if filter[:project] do
      q
        |> join(:inner, [r],
                p in Serverboards.Project.Model.Project,
                r.project_id == p.id)
        |> where([_r, p], p.shortname == ^filter[:project])
    else q end

    for r <- Repo.all(q) do
      decorate(r)
    end
  end

  defp get_project(shortname) do
    import Ecto.Query

    Repo.one(
      from r in Model.Rule,
      join: p in Serverboards.Project.Model.Project,
        on: p.id == r.project_id,
      where: r.uuid == ^shortname,
      select: p.shortname
    )
  end

  defp get_project_id_by_shortname(shortname) do
    import Ecto.Query

    Repo.one(
      from p in Serverboards.Project.Model.Project,
      where: p.shortname == ^shortname,
      select: p.id
    )
  end

  def get_state( uuid ) do
    import Ecto.Query

    Repo.one(
      from s in Model.RuleState,
      join: r in Model.Rule,
        on: r.id == s.rule_id,
      select: s.state,
      where: r.uuid == ^uuid
    )
  end

  # Server impl
  def init([]) do
    {:ok, %{}}
  end

end
