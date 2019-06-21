import React from 'react'
import View from 'app/components/menu/projectselector'
import { goto } from 'app/utils/store'
import connect from 'app/containers/connect'
import {project_update_all} from 'app/actions/project'
import {has_perm_guard} from 'app/restricted'
import { toggle_project_selector } from 'app/actions/menu'

var Container=has_perm_guard("project.get", connect({
  state: (state) => {
    return {
      current: state.project.current,
      projects: state.project.projects || []
    }
  },
  handlers: (dispatch) => ({
    onServiceSelect: (shortname) => dispatch( goto( `/project/${shortname}/`) ),
    onClose: () => dispatch( toggle_project_selector() )
  }),
  subscriptions: ["project.created", "project.deleted", "project.updated"],
  store_enter: [project_update_all],
  watch: ["projects", "current"]
})(View))

const MaybeContainer = connect({
  state: (state) => ({
    project_selector: state.menu.project_selector
  })
})( ({project_selector}) => project_selector ? (
  <Container/>
) : (
null
) )


export default MaybeContainer
