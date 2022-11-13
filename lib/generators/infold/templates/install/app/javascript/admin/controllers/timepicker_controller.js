import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="timepicker"
export default class extends Controller {
  connect() {
    flatpickr(this.element, { allowInput: true, enableTime: true, noCalendar: true, time_24hr: true })
  }
}
