import React from 'react'
import { connect } from 'react-redux'
import AddServiceView from 'app/components/project/addservice'
import { services_update_catalog, services_update_all, service_add } from 'app/actions/service'
import { project_attach_service } from 'app/actions/project'
import rpc from 'app/rpc'
import Flash from 'app/flash'

function service_add_future(sbds, service){
  return rpc.call("service.create", service).then(function(service_uuid){
    console.log("UUID is %o", service_uuid)
    if (sbds){
      return rpc.call("service.attach",[sbds, service_uuid]).then(function(){
        Flash.info("Added service and attached to project")
      }).then( () => service_uuid )
    }
    else{
      Flash.warning("Added DETACHED service")
      return service_uuid
    }
  })
}

var AddService=connect(
  (state) => {
    return {
      catalog: state.services.catalog,
      all_services: state.services.services,
      location: state.router.location.pathname
    }
  },
  (dispatch) => ({
    updateServiceCatalog: () => dispatch( services_update_catalog() ),
    updateAllServiceCatalog: () => dispatch( services_update_all() ),
    onAttachService: (a,b) => dispatch( project_attach_service(a,b) ),
    onAddService: (a,b) => service_add_future(a,b),
  })
)(AddServiceView)

export default AddService
