import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="relation-search"
export default class extends Controller {
  static targets = [ "selectedId", "selectedName" ]

  connect() {
  }

  select(event) {
    event.preventDefault()
    this.selectedIdTarget.value = event.currentTarget.dataset.id
    this.selectedNameTarget.value = event.currentTarget.dataset.name
  }

  relationClear(event) {
    event.preventDefault()
    this.selectedIdTarget.value = ''
    this.selectedNameTarget.value = ''
  }
}
