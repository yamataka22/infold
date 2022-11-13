import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="index-page"
export default class extends Controller {
    static targets = [ "wrapper", "resultArea", "resultTableWrapper", "searchForm", "thead", "sortField", "sortKind" ]

    connect() {
        if (window.innerWidth > 767) {
            document.addEventListener("turbo:load", ()=> {
                // 画面の高さを調整
                let main_top = this.wrapperTarget.getBoundingClientRect().top;
                this.resultAreaTarget.style.height = `${window.innerHeight - main_top}px`
                let table_wrapper = this.resultTableWrapperTarget;
                if (table_wrapper !== undefined) table_wrapper.style.height = `${window.innerHeight - main_top - 100}px`
            })
        }
    }

    outputCsv(event) {
        event.preventDefault()
        let currentAction = this.searchFormTarget.action;
        this.searchFormTarget.action = `${currentAction}.csv`
        this.searchFormTarget.requestSubmit()
        this.searchFormTarget.action = currentAction
    }

    sortChange(event) {
        event.preventDefault()
        this.sortFieldTarget.value = event.currentTarget.dataset.sortField
        this.sortKindTarget.value = event.currentTarget.dataset.sortKind
        this.searchFormTarget.requestSubmit()
    }
}
