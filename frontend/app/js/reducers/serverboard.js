import {merge} from 'app/utils'

var default_state={
  serverboards: [],
  current: undefined,
  serverboard: undefined,
  catalog: undefined,
  widgets: undefined
}

function serverboard(state=default_state, action){
  switch(action.type){
    case '@@router/LOCATION_CHANGE':
    {
      let current=action.payload.pathname.replace(RegExp("^/serverboard/([^/]*)/.*"), "$1")
      return merge(state, {current} )
    }
    case 'UPDATE_ALL_SERVERBOARDS':
      return merge(state, {serverboards: action.serverboards} )
    case 'UPDATE_SERVICE_CATALOG':
      return merge(state, {catalog: action.services} )
    case 'UPDATE_ALL_SERVICES':
      return merge(state, {all_services: action.services} )
    case 'UPDATE_SERVERBOARD_SERVICES':
      return merge(state, {current_services: action.services} )
    case '@RPC_EVENT/serverboard.added':
      return merge(state, {serverboards: state.serverboards.concat(action.serverboard) } )
    case '@RPC_EVENT/serverboard.deleted':
      return merge(state, {serverboards: state.serverboards.filter( s => s.shortname != action.shortname ) } )
    case '@RPC_EVENT/serverboard.updated':
      {
        let serverboards = state.serverboards.map( s => {
          if (s.shortname == action.shortname){
            return action.serverboard
          }
          return s
        })
        let serverboard = serverboards.find( (s) => s.shortname == state.current )

        return merge(state, {serverboards, serverboard})
      }
    case '@RPC_EVENT/service.updated':
      {
        let changed = false
        let current_services = state.serverboard.services.map( s => {
          if (s.uuid == action.service.uuid){
            changed = true
            if (action.service.serverboards.indexOf(state.current)>=0)
              return action.service
            else
              return undefined
          }
          return s
        }).filter( (s) => s != undefined )
        if (!changed && action.service.serverboards && action.service.serverboards.indexOf(state.current)>=0)
          current_services.push(action.service)
        return merge(state, {serverboard: merge(state.serverboard, {services: current_services})})
      }
    case 'UPDATE_SERVERBOARD_WIDGETS':
      const widgets=action.widgets
      return merge(state, {widgets})
    case "@RPC_EVENT/serverboard.widget.added":
      return merge(state, {widgets: state.widgets.concat(action)})
    case "@RPC_EVENT/serverboard.widget.updated":
      return merge(state, {widgets: state.widgets.map( (w) => {
        if (w.uuid==action.uuid)
          return merge(w, {config: action.config})
        return w
      }) } )
    case "@RPC_EVENT/serverboard.widget.removed":
      return merge(state, {widgets: state.widgets.filter( (w) => (w.uuid != action.uuid ) )} )
    case "UPDATE_SERVERBOARD_INFO":
      return merge(state, {serverboard: action.info})
      break;
  }
  return state
}

export default serverboard
