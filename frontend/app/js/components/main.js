import React from 'react';

import Top from 'app/containers/menu/top'
import Login from 'app/containers/login.js'
import FlashMessageList from 'app/containers/flashmessages.js'
import Router from 'app/router'
import get_modal from './modalfactory'
import Piwik from 'app/containers/piwik.js'
import {ErrorBoundary} from 'app/components/error'
import Legal from 'app/components/login/legal'
import Sidebar from 'app/containers/menu/sidebar'
import Hook from 'app/containers/hooks'
import ProjectSelector from 'app/containers/menu/projectselector'
import Tip from 'app/components/tip'
import i18n from 'app/utils/i18n'

function modal(props){
  let modal = []
  if (props.location && props.location.state && props.location.state.modal){
    const mod = props.location.state
    const Modal = get_modal(mod.modal)
    if (Modal){
      // console.log("Render Modal %o -> %o", mod.modal, Modal)
      const dispatch = require('app/utils/store').default.dispatch
      const goBack = require('app/utils/store').back
      modal=(
        <ErrorBoundary>
          <Modal {...mod.data} onClose={ () => dispatch( goBack() ) }/>
        </ErrorBoundary>
      )
    }
    else{
      console.error("Error rendering modal: %o. Not found.", mod.modal)
    }
  }
  return modal
}


function Main(props){
  var contents=[]
  if (!props.logged_in) {
    contents=(
      <Login onLogin={props.onLogin}/>
    )
  } else if (!props.has_perms) {
    const NOCONTENT_IMG = require("../../imgs/026-illustration-nocontent.svg")

    contents = (
      <Tip
        title={i18n("No permissions")}
        top_img={NOCONTENT_IMG}
        subtitle={i18n("Without permissions there is nothing to do.")}
        description={i18n("Ask your Serverboards administrator to add you to the users group and add some permissions.")}
        extra={(
          <a href="/">Try login again</a>
        )}
        />
    )
  } else if (props.licenses.length != 0) {
    contents = (
      <Legal
        lang={props.lang}
        license={props.licenses[0]}
        onLogout={props.onLogout}
        onAcceptLegal={() => props.onAcceptLegal(props.licenses[0].id)}
        />
    )
  } else {
    contents=(
      <div id="chrome">
        <Top onLogout={props.onLogout}/>
        <Sidebar/>
        <ProjectSelector/>

        <ErrorBoundary>
          <div className="ui main area" id="mainarea">
            <Router/>
            {modal(props)}
          </div>
        </ErrorBoundary>
      </div>
    )
  }

  return (
    <React.Fragment>
      <Piwik/>
      <FlashMessageList/>
      <Hook name="outchrome"/>
      {contents}
    </React.Fragment>
  )
}

export default Main
