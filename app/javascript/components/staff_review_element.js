import { controller, targets } from "@github/catalyst"

// In-place approve/reject for the stafftools meetups queue.
//
// Wraps the meetups list; the approve `button_to` and reject `form_with` both
// bubble their `submit` here. Instead of the default full-page navigation we
// PATCH via fetch and update the DOM: remove the reviewed card, refresh the
// status-count chips, and flash a toast — so moderating the queue never reloads
// the page. Falls back to normal form submission if JS is disabled.
//
// Usage in a view:
//   <staff-review data-action="submit:staff-review#submit">
//     <span data-targets="staff-review.counts" data-status="pending">…</span>
//     <article data-review-card>…forms…</article>
//   </staff-review>
class StaffReviewElement extends HTMLElement {
  async submit(event) {
    const form = event.target
    if (!(form instanceof HTMLFormElement)) return

    event.preventDefault()

    const confirmMessage = form.dataset.confirm
    if (confirmMessage && !window.confirm(confirmMessage)) return

    const card = form.closest("[data-review-card]")
    const buttons = form.querySelectorAll("button, input[type=submit]")
    buttons.forEach((button) => (button.disabled = true))

    try {
      const response = await fetch(form.action, {
        method: "post",
        body: new FormData(form),
        headers: { Accept: "application/json", "X-Requested-With": "XMLHttpRequest" },
      })
      const data = await response.json()

      if (response.ok && data.ok) {
        this.updateCounts(data.counts)
        this.removeCard(card)
        this.toast(data.notice, "notice")
      } else {
        buttons.forEach((button) => (button.disabled = false))
        this.toast(data.alert || "Something went wrong.", "alert")
      }
    } catch (error) {
      buttons.forEach((button) => (button.disabled = false))
      this.toast("Something went wrong. Please try again.", "alert")
    }
  }

  updateCounts(counts) {
    if (!counts) return
    this.counts.forEach((chip) => {
      const value = counts[chip.dataset.status]
      if (value !== undefined) chip.textContent = value
    })
  }

  removeCard(card) {
    if (!card) return
    card.style.transition = "opacity 200ms ease"
    card.style.opacity = "0"
    setTimeout(() => {
      const list = card.parentElement
      card.remove()
      if (list && !list.querySelector("[data-review-card]")) window.location.reload()
    }, 200)
  }

  // Mirror the flash markup from the stafftools layout, auto-dismissed.
  toast(message, kind) {
    if (!message) return
    const wrap = document.createElement("div")
    wrap.className = "fixed inset-x-0 top-4 z-50 mx-auto max-w-7xl px-6 sm:px-10"
    const classes =
      kind === "alert"
        ? "rounded-xl bg-red-50 px-4 py-3 text-sm text-red-800 ring-1 ring-red-200 shadow-lg"
        : "rounded-xl bg-green-50 px-4 py-3 text-sm text-green-800 ring-1 ring-green-200 shadow-lg"
    const note = document.createElement("div")
    note.className = classes
    note.textContent = message
    wrap.append(note)
    document.body.append(wrap)
    setTimeout(() => wrap.remove(), 3500)
  }
}

targets(StaffReviewElement.prototype, "counts")

controller(StaffReviewElement)

export default StaffReviewElement
