// Entry point for the build script in your package.json
import "bootstrap/dist/js/bootstrap.bundle.min.js"
import CopyToClipboard from './components/copy-to-clipboard'
import TomSelect from 'tom-select'

const $copyToClipboard = document.querySelector('[data-module="copy-to-clipboard"]')
if ($copyToClipboard) {
  new CopyToClipboard($copyToClipboard).init()
}