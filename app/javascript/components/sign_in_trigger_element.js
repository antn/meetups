import { controller } from "@github/catalyst"

// Wraps a control that requires a signed-in OffKai Expo account (claiming a
// slot, RSVPing) for visitors who aren't logged in. Clicking anywhere inside
// opens the shared sign-in modal instead of navigating (see
// sign_in_dialog_element.js).
class SignInTriggerElement extends HTMLElement {
  connectedCallback() {
    this.addEventListener("click", this.prompt)
  }

  prompt(event) {
    event.preventDefault()
    document.dispatchEvent(new CustomEvent("sign-in:open"))
  }
}

controller(SignInTriggerElement)

export default SignInTriggerElement
