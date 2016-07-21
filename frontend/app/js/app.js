// main.js
var React = require('react');
var ReactDOM = require('react-dom');
import { Provider } from 'react-redux'
import rpc from 'app/rpc'
import store from 'app/utils/store'
import plugin from 'app/utils/plugin'

require("sass/serverboards.sass")

import Main from 'app/containers/main.js'

import Flash from 'app/flash'
import FlashActions from 'app/actions/flash'

Flash.log=function(message, options={}){
  options=Object.assign({}, {timeout: 1000 + (message.length*200)}, options)
  store.dispatch( FlashActions.add(message, options) )
  var close =function(){
    store.dispatch(FlashActions.remove(message))
  }
  setTimeout(close, options.timeout)
  return {close}
}

window.Serverboards = {
  rpc,
  store,
  Flash,
  React,
  add_screen: plugin.add_screen,
}

ReactDOM.render(
  (
    <Provider store={store}>
      <Main/>
    </Provider>
  ),
  document.getElementById('react')
);
