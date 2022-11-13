import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="remote-modal"
export default class extends Controller {
  connect() {
    this.modalWindow = new bootstrap.Modal(this.element)
    if (this.element.dataset.modalKind === 'modal_sub') {
      // 既存のsubモーダルを閉じる
      document.currentModals.forEach((otherModal, i) => {
        if (otherModal.kind === 'modal_sub') otherModal.window.hide()
      })
    } else {
      // 既存の全モーダルを閉じる
      document.currentModals.forEach(otherModal => {
        otherModal.window.hide()
      })
    }
    this.modalWindow.show()
    document.currentModals.push({ window: this.modalWindow, element: this.element, kind: this.element.dataset.modalKind })

    this.element.addEventListener('hide.bs.modal', function (event) {
      document.currentModals.pop()
    })
  }

  submitEnd(e) {
    if (e.detail.success) {
      close()
    }
  }

  close() {
    this.element.parentElement.removeAttribute("src")
    this.element.remove()
    this.modalWindow.hide()
  }
}
