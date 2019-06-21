import rpc from 'app/rpc'
import Flash from 'app/flash'
import moment from 'moment'
import { goto } from 'app/utils/store'
import i18n from 'app/utils/i18n'
import {map_get, to_mapf} from 'app/utils'

function project_update_all(){
  return function(dispatch){
    rpc.call("project.list",[]).then(function(data){
      dispatch({type: "UPDATE_ALL_PROJECTS", projects: data})
    })
  }
}

function project_add(data){
  return function(dispatch, store){
    rpc.call("project.create",
        [ data.shortname, {name: data.name, tags: data.tags, description: data.description}]
      ).then(function(){
        dispatch( goto({pathname: `/project/${data.shortname}/`}) )
        Flash.info(i18n("Added project *{shortname}*", {shortname: data.shortname}))
      })
  }
}

function project_delete(shortname){
  return function(dispatch){
    rpc.call("project.delete", [shortname]).then(function(){
      Flash.info(i18n("Removed project *{shortname}*", {shortname: data.shortname}))
    })
  }
}

function project_update(shortname, changes){
  return function(dispatch){
    rpc.call("project.update", [shortname, changes]).then(function(){
      Flash.info(i18n("Updated project *{shortname}*", {shortname}))
    })
  }
}

function project_attach_service(project_shortname, service_uuid){
  return function(dispatch){
    rpc.call("service.attach",[project_shortname, service_uuid]).then(function(){
      Flash.info(i18n("Added service to project"))
    })
  }
}

function projects_set_current(shortname){
  return function(dispatch){
    dispatch({type:"PROJECT_SET_CURRENT", payload: shortname})
    dispatch( projects_update_info(shortname) )
  }
}

function projects_update_info(project){
  return function(dispatch){
    dispatch({type:"UPDATE_PROJECT_INFO", project, info: undefined})
    if (project){
      rpc.call("project.get", [project]).then( (info) => {
        dispatch({type:"UPDATE_PROJECT_INFO", project, info})
        dispatch( project_get_dashboard(map_get(info.dashboards, [0, "uuid"])))
      })
    }
  }
}

function project_update_widget_catalog(){
  return function(dispatch){
    rpc.call("plugin.component.catalog", {type: "widget"}).then( (catalog) => {
      const payload = to_mapf(catalog, c => c.id)
      dispatch({type:"UPDATE_WIDGET_CATALOG", payload: payload})
    })
  }
}

function board_set_daterange_start(start){
  start = start.format()
  return {
    type: "UPDATE_DATERANGE",
    daterange: { start }
  }
}

function board_set_daterange_end(end){
  end = end.format()
  return {
    type: "UPDATE_DATERANGE",
    daterange: { end }
  }
}

function board_set_daterange_start_and_end(start, end, rt){
  return {
    type: "UPDATE_DATERANGE",
    daterange: { start, end, rt }
  }
}

function board_update_now(){
  return {
    type: "UPDATE_DATERANGE",
    daterange: { now: moment() }
  }
}

function board_set_realtime(enabled){
  return {
    type: "UPDATE_DATERANGE",
    daterange: { rt: enabled }
  }
}

function project_get_dashboard(uuid){
  return function(dispatch){
    dispatch({type: "BOARD_SET", payload: undefined })
    if (uuid)
      rpc.call("dashboard.get", {uuid}).then( d => {
        dispatch({type: "BOARD_SET", payload: d})
      })
  }
}

function board_update(data){
  return rpc
    .call("dashboard.update", data)
    .then( () => {
      Flash.info(i18n(`Updated dashboard *{name}*`, data))
      return {type: "BOARD_UPDATE", payload: data}
    })
}

function board_remove({uuid, name}){
  return rpc
    .call("dashboard.delete", {uuid})
    .then( () => {
      Flash.info(i18n(`Removed dashboard *{name}*`, {name}))
      return {type: "BOARD_REMOVED", payload: uuid}
    })
}

function dashboard_list(project){
  console.log("Get dashboard list ", project)
  return rpc
    .call("dashboard.list", {project})
    .then( list => ({
      type: "DASHBOARD_LIST",
      payload: {list, project}
    }))
}

function board_update_rt_daterange(){
  return {
    type: 'UPDATE_RT_DATERANGE'
  }
}

export {
  project_add,
  project_update_all,
  project_delete,
  project_update,
  project_attach_service,
  projects_set_current,
  projects_update_info,
  project_update_widget_catalog,
  project_get_dashboard,
  board_set_daterange_end,
  board_set_daterange_start,
  board_set_daterange_start_and_end,
  board_update_now,
  board_set_realtime,
  board_update,
  board_remove,
  board_update_rt_daterange,
  dashboard_list,
}
