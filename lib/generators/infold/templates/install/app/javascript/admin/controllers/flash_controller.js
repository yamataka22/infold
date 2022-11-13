import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  connect() {
    setTimeout( () => {
      this.element.style.display = "none";
    }, 4000);
  }
}
