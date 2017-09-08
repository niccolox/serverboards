// Components that will be exported to be used at plugins. Mainly third party.
import {MarkdownPreview} from 'react-marked-markdown'
import ActionEdit from 'app/components/rules/actionedit'
import Loading from './loading'
import Modal from './modal'
import HoldButton from './holdbutton'
import GenericForm from './genericform'
import Calendar from './calendar'
import Error from './error'

const components = {
  Modal,
  Loading,
  MarkdownPreview,
  ActionEdit,
  HoldButton,
  GenericForm,
  Calendar,
  Error
}

export default components
