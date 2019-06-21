import GroupsView from 'app/components/settings/groups'
import {
    group_list, user_list,
    group_remove,
  } from '../../actions/auth'
import { set_modal } from 'app/actions/modal'
import connect from 'app/containers/connect'

var Groups = connect({
  state: (state) => ({
    groups : state.auth.groups,
    location: state.router.location.pathname,
    all_users: (state.auth.users || []).map( (u) => u.email ),
    all_perms: state.auth.all_perms
  }),
  handlers: (dispatch) => ({
    onRemoveGroup: (g) => dispatch( group_remove(g) ),
    setModal: (modal, data) => dispatch( set_modal(modal, data) )
  }),
  subscriptions: ["group.user_added", "group.user.deleted",
   "group.perm_added", "group.perm.deleted",
   "group.created", "group.deleted",
   "user.updated", "user.created"],
  store_enter: [group_list, user_list]
})(GroupsView)

export default Groups
