import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (this.element.value !== "") {
      this.element.classList.add("has-value");
    }
  }

  toggleStateClass() {
    this.element.classList.toggle("has-value", this.element.value !== "")
  }
}
