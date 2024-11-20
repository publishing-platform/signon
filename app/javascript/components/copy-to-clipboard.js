function CopyToClipboard ($module) {
  this.$module = $module
  this.$input = this.$module.querySelector('.copy-to-clipboard-target')
  this.$copyButton = this.$module.querySelector('.copy-to-clipboard-button')
}

CopyToClipboard.prototype.init = function () {
  if (!this.$input || !this.$copyButton) return

  this.$input.addEventListener('click', function () {
    this.$input.select()
  }.bind(this))

  this.$copyButton.addEventListener('click', function (event) {
    event.preventDefault()
    this.$input.select()
    document.execCommand('copy')
  }.bind(this))
}

export default CopyToClipboard
