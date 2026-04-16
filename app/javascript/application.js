// Entry point for the build script in your package.json
import { initAll } from '@publishing-platform/publishing-platform-publishing-components'
import CopyToClipboard from './components/copy-to-clipboard'

initAll()

const $copyToClipboard = document.querySelector('[data-module="copy-to-clipboard"]')
if ($copyToClipboard) {
  new CopyToClipboard($copyToClipboard).init()
}
