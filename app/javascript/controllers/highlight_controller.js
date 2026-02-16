import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.classList.add('highlighted');
    setTimeout(() => {
      this.element.classList.remove('highlighted');
    }, 150)

    // Second blink
    setTimeout(() => {
      this.element.classList.add('highlighted');
    }, 300)
    setTimeout(() => {
      this.element.classList.remove('highlighted');
    }, 450)
  }
}
