// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
// import * as ActiveStorage from "@rails/activestorage"
// ActiveStorage.start()
import "./admin/controllers"
import "./admin/custom.css"

document.currentModals = []