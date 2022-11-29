// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import('@rails/activestorage')
    .then(ActiveStorage => { ActiveStorage.start() })
    .catch()
import "./admin/controllers"
import "./admin/admin.css"

document.currentModals = []