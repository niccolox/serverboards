import React from 'react'
import {servername} from 'app/utils'
require("sass/logoicon.sass")

function IconIcon(props){
  if (!props.icon)
    return null
  if (props.icon.startsWith("data:")){
    const imgurl = props.icon
    return (
      <span className={`ui iconicon ${props.className || "normal"}`}>
        <span className="icon">
          <img src={imgurl} style={props.style}/>
        </span>
      </span>
    )
  } else if (props.icon.endsWith(".svg") || props.icon.endsWith(".png") ||
             props.icon.endsWith(".jpg") || props.icon.endsWith(".gif") ){
    const imgurl=`${servername()}/static/${props.plugin}/${props.icon}`
    return (
      <span className={`ui iconicon ${props.className || "normal"} ${props.src ? "with background" : ""}`}>
        {props.src ? (
          <img src={props.src} className="base" style={props.style}/>
        ) : null}
        <span className="icon">
          <img src={imgurl} style={props.style}/>
        </span>
      </span>
    )
  }
  return (
    <span className={`ui iconicon ${props.className || "normal"} ${props.src ? "with background" : ""}`}>
      {props.src ? (
        <img src={props.src} className="base" style={props.style}/>
      ) : null}
      <i className={`ui ${props.icon} icon`} style={props.style}/>
    </span>
  )
}

export default IconIcon
