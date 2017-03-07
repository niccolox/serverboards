require Logger

defmodule Serverboards.Project.RPC do
  alias MOM.RPC
  alias MOM.RPC.Context
  alias MOM
  import Serverboards.Project

  def start_link(options \\ []) do
    {:ok, mc} = RPC.MethodCaller.start_link options

    # Adds that it needs permissions.
    Serverboards.Utils.Decorators.permission_method_caller mc

    # Serverboards
    RPC.MethodCaller.add_method mc, "project.add", fn [projectname, options], context ->
      project_add projectname, options, Context.get(context, :user)
    end, [required_perm: "project.add", context: true]

    RPC.MethodCaller.add_method mc, "project.delete", fn [project_id], context ->
      project_delete project_id, Context.get(context, :user)
    end, [required_perm: "project.add", context: true]

    RPC.MethodCaller.add_method mc, "project.update", fn
      [project_id, operations], context ->
        project_update project_id, operations, Context.get(context, :user)
      end, [required_perm: "project.update", context: true]

    RPC.MethodCaller.add_method mc, "project.get", fn [project_id], context ->
      {:ok, project} = project_get project_id, Context.get(context, :user)
      {:ok, Serverboards.Utils.clean_struct project}
    end, [required_perm: "project.get", context: true]

    RPC.MethodCaller.add_method mc, "project.list", fn [], context ->
      {:ok, projects} = project_list Context.get(context, :user)
      Enum.map projects, &Serverboards.Utils.clean_struct(&1)
    end, [required_perm: "project.get", context: true]


    RPC.MethodCaller.add_method mc, "dashboard.widget.add", fn attr, context ->
      me = Context.get(context, :user)
      Serverboards.Project.Widget.widget_add(attr["project"], %{
        config: attr["config"],
        ui: attr["ui"],
        widget: attr["widget"]
        }, me)
    end, [required_perm: "dashboard.widget.add", context: true]

    RPC.MethodCaller.add_method mc, "dashboard.widget.remove", fn [uuid], context ->
      me = Context.get(context, :user)
      Serverboards.Project.Widget.widget_remove(uuid, me)
    end, [required_perm: "dashboard.widget.add", context: true]

    RPC.MethodCaller.add_method mc, "dashboard.widget.update", fn attr, context ->
      me = Context.get(context, :user)
      config = [
        config: attr["config"],
        ui: attr["ui"],
        widget: attr["widget"]
        ] |> Enum.filter( fn {_key, value} -> value != nil end )
          |> Map.new

      Serverboards.Project.Widget.widget_update(attr["uuid"], config, me)
    end, [required_perm: "dashboard.widget.update", context: true]

    RPC.MethodCaller.add_method mc, "dashboard.widget.list", fn [shortname] ->
      Serverboards.Project.Widget.widget_list(shortname)
    end, [required_perm: "project.get"]

    RPC.MethodCaller.add_method mc, "dashboard.widget.catalog", fn [project] ->
        Serverboards.Project.Widget.catalog(project)
    end, [required_perm: "project.get"]

    # Add this method caller once authenticated.
    MOM.Channel.subscribe(:auth_authenticated, fn %{ payload: %{ client: client }} ->
      MOM.RPC.Client.add_method_caller client, mc
      :ok
    end)

    {:ok, mc}
  end
end
