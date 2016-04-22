import redux_reducers from '../reducers'
import rpc from '../rpc'

var redux_middleware, redux_extra
import { createStore, applyMiddleware } from 'redux'
if (__DEV__){
  console.warn("Running in DEBUG mode")

/*
  redux_middleware=applyMiddleware( store => next => action => {
    console.group(action.type)
    console.log(action)
    let result
    try{
      result = next(action)
    }
    catch(e){
      console.log("Error processing %o: %o", action.type, e)
    }
    console.log(store.getState())
    console.groupEnd(action.type)
    return result
  })
*/
  redux_extra=window.devToolsExtension ? window.devToolsExtension() : f => f
}

let store = createStore(
  redux_reducers,
  redux_middleware,
  redux_extra
)

function get_value(what){
  function get_value_r(whatl, state){
    if (whatl.length==1)
      return state[whatl[0]]
    return get_value_r(whatl.slice(1), state[whatl[0]])
  }
  return get_value_r(what.split('.'), store.getState())
}

function object_equals(o1, o2){
  let to1=typeof(o1)
  let to2=typeof(o2)
  //console.log("Compare %o==%o, %o==%o", o1, o2, to1, to2)
  if (to1=='undefined' && to2=='undefined')
    return true // Not really true, but it is for our use case
  if (to1!=to2)
    return false;

  if (to1=='object'){
    let k
    for(k in o1){
      if (k.slice(2)!='__')
        if (!object_equals(o1[k], o2[k]))
          return false;
    }
    return true
  }
  return o1==o2
}

/**
 * @short Adds simple .on(what, f) observer
 *
 * It observes for changes in the state, and when change,
 * calls the f.
 */
store.on=function(what, f){
  let current_v=get_value(what)
  store.subscribe(function(){
    let new_v=get_value(what)
    if (!object_equals(current_v,new_v)){
      current_v=new_v
      //console.log("Changed status %o != %o", current_v, new_v)
      try{
        f(new_v)
      }
      catch(e){
        console.error("Error on %o observer: %o", what, e)
      }
    }
  })
}

rpc.set_redux_store(store)

export default store
