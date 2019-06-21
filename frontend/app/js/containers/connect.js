import React from 'react'
import {unwrap, object_is_equal, map_get} from 'app/utils'
import event from 'app/utils/event'
import { connect } from 'react-redux'
import Loading from 'app/components/loading'
import PropTypes from 'prop-types'
import store from 'app/utils/store'

/**
 * Expanded version of redux.connect
 *
 * I allow to do the same, but also some other
 * required funcionality, as request state, use promises for state, improved
 * propery change detection.
 *
 * To use it as a replacement, use state and handlers options.
 *
 * All options can be a list/map or a function(props, state). If its a function
 * it will be reexcuted for every state or props change (see watch), and the
 * result used.
 *
 * It creates a layered system where:
 *  1. Call the updaters
 *  2. Do subscriptions
 *  3. Get state using react redux
 *
 * In the functions, state is always the store state, and props are received
 * props. If your code needs the generated state from `state`, call it with
 * `this.state(state, props)`.
 *
 * options:
 *   state(state, props)
 *            same as redux first parameter.
 *            if the original props or state changes (from redux), its reexecuted
 *            see `watch` to limit this reexcution.
 *   handlers(dispatch, props)
 *            functions to be executed as handlers.
 *   subscriptions(state, props)
 *            Subscribes to serverboards events. At umount desubscribes. On event
 *            refreshes. Its a list of events to subscribe.
 *   store_enter(state, props)
 *            Functions to call for redux to update the state, for example load
 *            current service
 *   store_exit(state, props)
 *            Functions to call for redux to clean the state when leaving, for
 *            example unload current service.
 *   watch
 *            Props elements to watch, if any changes, update the component data
 *            store and resubscribe.
 *   loading(state, props)
 *            Returns a string to show in a loading component or false if all
 *            data ready. Doing it here prevents downstream component to get
 *            undefined states
 *   promises(state, props)
 *            Returns a dict with keys and promises, that when resolved will
 *            set that key on state to the result of that promise.
 *
 * Use as redux connect: serverboards_connect(options)(View)
 */
export function serverboards_connect(options){
  return function(Component){
    class SubscribedConnect extends React.Component{
      constructor(props){
        super(props)
        this.state = { options }
      }
      _componentDidMount(props){ // Wrapper to allow call with specific props
        const state = store.getState()
        const subscriptions = unwrap(options.subscriptions, state, props)
        event.subscribe(subscriptions)

        const updates = unwrap(options.store_enter, state, props)
        updates.map( (u) => store.dispatch(u()) )
      }
      _componentWillUnmount(props){ // Wrapper to allow call with specific props
        const state = store.getState()
        const subscriptions = unwrap(options.subscriptions, state, props)
        event.unsubscribe(subscriptions)

        const store_clean = unwrap(options.store_exit, state, props)
        store_clean.map( (u) => store.dispatch(u()) )
      }
      componentDidMount(){
        this._componentDidMount(this.props)
        const state = store.getState()
        const promises = unwrap(options.promises, state, this.props)

        Object.keys(promises || {}).map( k => {
          promises[k].then( v => {
            let state_update={}
            state_update[k]=v
            this.setState(state_update)
          } ).catch( e => {
            console.error("Error setting promise value", k, e)
          })
        })
      }
      componentWillUnmount(){
        this._componentWillUnmount(this.props)
      }
      componentWillReceiveProps(newprops){
        if (!options.watch || options.watch == Object.watch)
          return;
        let update=false
        const state = store.getState()
        unwrap(options.watch, state, newprops).map( (p) => {
          let pl = p.split('.')
          if (!object_is_equal( map_get(this.props, pl), map_get(newprops, pl)))
            update=true
        })
        if (update){
          this._componentWillUnmount(this.props)
          this._componentDidMount(newprops)
        }
      }
      render(){
        if (options.loading){
          const loading = options.loading(store.getState(), this.props)
          if (loading)
            return (
              <Loading>{loading}</Loading>
            )
        }

        return (
          <Component {...this.state} {...this.props}/>
        )
      }
    }
    SubscribedConnect.contextTypes = {
      store: PropTypes.object
    }

    return connect(options.state, options.handlers)(SubscribedConnect)
  }
}


export default serverboards_connect
