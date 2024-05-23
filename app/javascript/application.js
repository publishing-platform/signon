// Entry point for the build script in your package.json
import "bootstrap/dist/js/bootstrap.bundle.min.js"
import TomSelect from 'tom-select'

document.querySelectorAll('.tom-select').forEach((el) => {
  const settings = {}
  new TomSelect(el, settings) // eslint-disable-line no-new
})

document.querySelectorAll('.tom-select-multiple').forEach((el) => {
  const settings = {
    plugins: {
      remove_button: true
    }
  }
  new TomSelect(el, settings) // eslint-disable-line no-new
})