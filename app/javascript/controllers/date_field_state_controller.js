import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggleStateClass() {
    this.element.classList.toggle("has-value", this.element.value !== "")
  }
}
