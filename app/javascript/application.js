// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import "./components"
import { install, uninstall } from "@github/hotkey"

// Binds keyboard shortcuts (e.g. Shift+A on the staffbar's stafftools link)
// declared via `data-hotkey` attributes.
function installHotkeys() {
  for (const el of document.querySelectorAll("[data-hotkey]")) {
    install(el)
  }
}

document.addEventListener("DOMContentLoaded", installHotkeys)
document.addEventListener("turbo:load", installHotkeys)
document.addEventListener("turbo:before-cache", () => {
  for (const el of document.querySelectorAll("[data-hotkey]")) {
    uninstall(el)
  }
})
