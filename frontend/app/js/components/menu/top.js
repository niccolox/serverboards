import React from 'react'
import {Link} from 'app/router'
import {goto} from 'app/utils/store'
import Restricted from 'app/restricted'
import i18n from 'app/utils/i18n'
import { get_last_project } from 'app/utils/project'
import {menu} from 'app/containers/menu'
import Hook from 'app/containers/hooks'

require("sass/top.sass")
const icon_plugin = require("../../../imgs/007-icon-plugins.svg")

class Top extends React.Component{
  constructor(props){
    super(props)

    this.state = {
      timeid: 1
    }
  }
  componentDidMount(){
    menu.real = this
  }
  componentWillUnmount(){
    menu.real = null
  }
  render(){
    const {props} = this
    const Menu = menu.menu
    // console.log("render top", menu, Menu)
    const section=props.section
    let logo=require("../../../imgs/favicon.png")
    return (
      <nav key={props.lang} className="ui serverboards top menu" id="top-menu" ref="el">
        {!props.sidebar && (
          <React.Fragment>
            <a className="item" onClick={props.onToggleSidebar}>
              <i className="ui bars big icon" style={{fontSize: 28}}/>
            </a>
            <div className="item logo">
              <a href="#/">
                <img src={logo}/>
              </a>
            </div>
            <span className="item separator"/>
          </React.Fragment>
        )}
        {Menu && (
          <Menu key={this.state.timeid} {...menu.props}/>
        )}
        <div className="right">
          <Hook name="topbar" section={section}/>
        </div>
      </nav>
    )
  }
}

export default Top
