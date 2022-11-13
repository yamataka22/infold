import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="nested-form"
export default class extends Controller {
    static targets = [ "links", "template" ]

    connect() {
        this.wrapperClass = this.data.get("wrapperClass") || "nested-fields"
    }

    add_association(event) {
        event.preventDefault()

        let content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
        this.linksTarget.insertAdjacentHTML('beforeend', content)
    }

    remove_association(event) {
        event.preventDefault()

        let wrapper = event.target.closest("." + this.wrapperClass)

        // New records are simply removed from the page
        if (wrapper.dataset.newRecord === "true") {
            wrapper.remove()

            // Existing records are hidden and flagged for deletion
        } else {
            wrapper.querySelector("input[name*='_destroy']").value = 1
            wrapper.style.display = 'none'
        }
    }
}
