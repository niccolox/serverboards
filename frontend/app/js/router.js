// using an ES6 transpiler, like babel
import React from 'react';
import { Router, Route, Link } from 'react-router-dom'
import { connect } from 'react-redux'
import store, { history } from 'app/utils/store'

import DashBoard from 'app/containers/dashboard'
import Profile from 'app/containers/profile'
import Settings from 'app/components/settings'
import Project from 'app/containers/project'
import ProcessesHistory from 'app/containers/processes'
import ProcessView from 'app/containers/processes/process'
import PluginScreen from 'app/containers/plugin/screen'
import Logs from 'app/containers/logs'
import Notification from 'app/components/notifications/notification'
import NotificationList from 'app/containers/notifications/list'
import Issues from 'app/containers/issues'
import IssuesAdd from 'app/containers/issues/add'
import IssuesView from 'app/containers/issues/details'
import ServiceDetails from 'app/containers/service/details'
import Wizard from 'app/containers/project/wizard'
import { ConnectedRouter } from 'connected-react-router'

class ServerboardsRouter extends React.Component{
  render(){
    //console.log("Router Props: %o", this.props)
    return (
        <ConnectedRouter history={history}>
          <Route path="/!" component={DashBoard}/>
          <Route path="/" component={DashBoard}/>
          <Route path="/user/profile" component={Profile}/>
          <Route path="/project/">
            <Route path="wizard" component={Wizard}/>
            <Route path=":project/" component={Project}/>
            <Route path=":project/:section" component={Project}/>
            <Route path=":project/:section/:subsection" component={Project}/>
            <Route path=":project/:section/:subsection/:service" component={Project}/>
          </Route>
          <Route path="/settings/" component={Settings}/>
          <Route path="/process/">
            <Route path="history" component={ProcessesHistory}/>
            <Route path=":uuid" component={ProcessView}/>
            <Route path="" component={ProcessesHistory}/>
          </Route>
          <Route path="/notifications/">
            <Route path="list" component={NotificationList}/>
            <Route path=":id" component={Notification}/>
          </Route>
          <Route path="/logs/" component={Logs}/>

          <Route path="/issues/" component={Issues}/>
          <Route path="/issues/">
            <Route path="add" component={IssuesAdd}/>
            <Route path=":id" component={Issues}/>
          </Route>

          <Route path="/services/">
            <Route path=":id" component={ServiceDetails}/>
          </Route>

          <Route path="/s/">
            <Route path=":plugin/:component" component={(props) => (
              <PluginScreen key={props.location.pathname} {...props}/>
            )}/>
          </Route>
        </ConnectedRouter>
      )
    }
}

export { Link }
export default ServerboardsRouter
