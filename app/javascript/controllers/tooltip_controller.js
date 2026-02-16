import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tooltip"]
  static values = { url: String }

  show(event) {
    const frame = this.tooltipTarget.querySelector("turbo-frame")
    const rect = this.tooltipTarget.getBoundingClientRect()
    const left = event.clientX + rect.width > window.innerWidth
        ? event.clientX - 12 - rect.width
        : event.clientX + 12

    if (frame && !frame.src) {
      frame.src = this.urlValue
    }

    this.tooltipTarget.style.position = "fixed"
    this.tooltipTarget.classList.remove("hidden")
    this.tooltipTarget.style.left = `${left}px`
    this.tooltipTarget.style.top = `${event.clientY}px`
  }

  hide() { this.tooltipTarget.classList.add("hidden") }
}
