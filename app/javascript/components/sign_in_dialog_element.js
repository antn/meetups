import { controller, target } from "@github/catalyst"

// Shared "sign in to continue" modal, rendered once in the layout for signed-out
// visitors (see SignInDialogComponent). Any control that needs authentication —
// claiming a slot, RSVPing — opens it by dispatching a `sign-in:open` event on
// the document (see sign_in_trigger_element.js), so triggers don't need a
// reference to the dialog.
class SignInDialogElement extends HTMLElement {
  connectedCallback() {
    this.open = this.open.bind(this)
    document.addEventListener("sign-in:open", this.open)
  }

  disconnectedCallback() {
    document.removeEventListener("sign-in:open", this.open)
  }

  open() {
    if (!this.dialog.open) this.dialog.showModal()
  }

  close() {
    this.dialog.close()
  }

  // Clicking the backdrop (the dialog element itself, outside its content) closes.
  backdrop(event) {
    if (event.target === this.dialog) this.dialog.close()
  }
}

target(SignInDialogElement.prototype, "dialog")

controller(SignInDialogElement)

export default SignInDialogElement
