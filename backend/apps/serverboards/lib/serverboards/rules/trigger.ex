require Logger

defmodule Serverboards.Rules.Trigger do
  alias Serverboards.Plugin
  def start_link options \\ [] do
    GenServer.start_link __MODULE__, :ok, options
  end

  @doc ~S"""
  Returns the list of possible triggers for the given filter.

  The filter is as in Plugin.Registry.filter_component
  """
  def find(filter \\ []) do
    Plugin.Registry.filter_component([type: "trigger"] ++ filter)
     |> Enum.map(fn tr ->
       states = case tr.extra["states"] do
         l when is_list(l) -> l
         str when is_binary(str) -> String.split(str)
         nil -> []
       end
       command = tr.extra["command"]
       #Logger.debug("Command is #{inspect command}")
       command = if String.contains?(command, "/") do
         command
       else
         "#{tr.plugin}/#{command}"
       end

       %{
         name: tr.name,
         description: tr.extra["description"],
         traits: tr.traits,
         command: command,
         start: tr.extra["start"],
         stop: tr.extra["stop"],
         id: tr.id,
         states: states
       }
      end)
  end

  @doc ~S"""
  Executes the command for a trigger
  """
  def start(trigger, params, cont) when is_map(trigger) do
    GenServer.call(Serverboards.Rules.Trigger, {:start, trigger, params, cont})
  end
  def start(triggerid, params, cont) when is_binary(triggerid) do
    case find id: triggerid do
      [trigger] ->
        start(trigger, params, cont)
      [] ->
        Logger.error("Could not find trigger #{triggerid}", trigger: triggerid)
        {:error, :not_found}
    end
  end

  def stop(uuid) do
    GenServer.call(Serverboards.Rules.Trigger, {:stop, uuid})
  end

  def get_trigger(uuid) do
    GenServer.call(Serverboards.Rules.Trigger, {:get_trigger, uuid})
  end

  def setup_client_for_rules(%MOM.RPC.Client{} = client) do
    #Logger.debug("Method caller of this trigger #{inspect client}")
    MOM.RPC.Client.add_method client, "trigger", fn
      [params] ->
        trigger_real(params)
      %{} = params ->
        trigger_real(params)
    end
  end

  def trigger_real(params) do
    case get_trigger(params["id"]) do
      nil ->
        Logger.warn("Invalid trigger triggered (#{params["id"]}). Check plugin trigger function.", params: params)
        {:error, :not_found}
      trigger ->
        Logger.debug("Trigger #{inspect trigger.trigger.id}, #{inspect params}")
        Plugin.Runner.ping(trigger.plugin_id)

        params = Map.merge(params, %{ trigger: trigger.trigger.id, id: params["id"] })
        trigger.cont.(params)
    end
  end

  def terminate(a,b) do
    Logger.error("Terminate trigger server with #{Enum.count b.triggers} rules", reason: a, state: b)
  end

  # impl
  def init(:ok) do
    {:ok, %{
      triggers: %{}
      }}
  end

  def handle_call({:start, trigger, params, cont}, _from, state) do
    case Plugin.Runner.start trigger.command do
      {:ok, plugin_id} ->
        {:ok, client} = Plugin.Runner.client plugin_id
        setup_client_for_rules client # can setup over without any problem. If not would need to setup only once.

        uuid = UUID.uuid4
        method = Map.put( trigger.start, "params", [%{ "name" => "id", "value" => uuid }] ++ Map.get(trigger.start, "params", []) )

        call_response = try do
          Plugin.Runner.call( plugin_id, method, params )
        catch # may cowardly exit the calling process (or already exited? just started!)
          :exit, _ -> {:error, :exit}
        end


        {res, uuid, triggerdata} = case call_response do
          {:ok, stop_id} ->
            stop_id = if stop_id do stop_id else uuid end

            Logger.info("Starting trigger #{inspect trigger.id} // #{uuid}", trigger: trigger, uuid: uuid)
            {:ok, uuid, %{ trigger: trigger, cont: cont, plugin_id: plugin_id, stop_id: stop_id } }
          {:error, error} ->
            Logger.error("Error starting trigger #{inspect trigger.id}: #{inspect error}", error: error, trigger: trigger)
            {:error, :aborted, %{}}
        end

        if res == :ok do
          {:reply, {:ok, uuid}, %{
            triggers: Map.put(state.triggers, uuid, triggerdata)
            }}
        else
          {:reply, {:error, :aborted}, state}
        end
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:stop, uuid}, _from, state) do
    Logger.debug("Try to stop trigger #{inspect uuid}")
    if Map.has_key?(state.triggers, uuid) do
      trigger=state.triggers[uuid]
      Logger.info("Stopping trigger #{inspect trigger.trigger.id} // #{uuid}", trigger: trigger, uuid: uuid)
      if trigger.trigger.stop do
        Plugin.Runner.call( trigger.plugin_id, trigger.trigger.stop, [trigger.stop_id] )
      end
      # maybe stop plugin if one_for_one strategy
      Plugin.Runner.stop( trigger.plugin_id )
      {:reply, :ok, %{ state |
        triggers: Map.drop(state.triggers, [uuid])}}
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:get_trigger, uuid}, _from, state) do
    {:reply, state.triggers[uuid], state}
  end
end
