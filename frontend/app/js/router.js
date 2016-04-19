// using an ES6 transpiler, like babel
import React from 'react';
import { Router, Route, Link, hashHistory } from 'react-router'
import { connect } from 'react-redux'
import { login, logout } from './actions/auth'

import Main from './components/main.js'
import Login from './containers/login.js'
import Console from './containers/console.js'

var ServerboardsRouter = React.createClass({
  render: function(){
    if (!this.props.logged_in){
      return (
        <div>
          <Console/>
          <Login onLogin={this.props.onLogin}/>
        </div>
      )
    }
    else{
      return (
        <Router history={hashHistory}>
          <Route path="/" component={Main}/>
        </Router>
      )
    }
  }
})

ServerboardsRouter=connect(
  (state) => {
    return {
      logged_in: state.auth.logged_in
    }
  },
  (dispatch) => {
    return {
      onLogin: ((user) => {
        dispatch(login(user))
      }),
      onLogout: (() => dispatch(logout()))
    }
  }
)(ServerboardsRouter)

export default ServerboardsRouter
