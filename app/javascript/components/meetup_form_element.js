import { controller, target } from "@github/catalyst"

// Cross-filters the meetup form's location and day/time dropdowns so a viewer
// can't pick a slot that's already taken. A booking is a (location, start-time)
// pair; selecting one side grays out the options on the other side that would
// collide.
//
// Usage:
//   <meetup-form data-booked='["12:1757696400", …]'>   // "<location_id>:<epoch>"
//     <select data-target="meetup-form.location" data-action="change:meetup-form#sync">…</select>
//     <select data-target="meetup-form.slot" data-action="change:meetup-form#sync">
//       <option data-epoch="1757696400">…</option>
//     </select>
//   </meetup-form>
class MeetupFormElement extends HTMLElement {
  connectedCallback() {
    this.booked = new Set(JSON.parse(this.dataset.booked || "[]"))
    this.sync()
  }

  sync() {
    const locationId = this.location.value
    const slotEpoch = this.location ? this.selectedEpoch() : null
    const nowEpoch = Math.floor(Date.now() / 1000)

    // Gray out times that have already passed or are already taken in the chosen
    // location, and show the full day+time on the selected option so the
    // collapsed control is clear.
    this.slot.querySelectorAll("option[data-epoch]").forEach((option) => {
      const epoch = Number(option.dataset.epoch)
      const past = epoch < nowEpoch
      const booked = Boolean(locationId) && this.booked.has(`${locationId}:${epoch}`)
      option.disabled = past || booked
      option.textContent = option.selected ? option.dataset.full : option.dataset.short
    })

    // Gray out the locations already taken at the chosen time.
    this.location.querySelectorAll("option").forEach((option) => {
      if (!option.value) return
      option.disabled = Boolean(slotEpoch) && this.booked.has(`${option.value}:${slotEpoch}`)
    })

    // If a selection just became disabled (e.g. switching sides into a clash),
    // clear it and re-run so the freed side opens back up.
    let cleared = false
    if (this.location.selectedOptions[0]?.disabled) {
      this.location.value = ""
      cleared = true
    }
    if (this.slot.selectedOptions[0]?.disabled) {
      this.slot.value = ""
      cleared = true
    }
    if (cleared) this.sync()
  }

  selectedEpoch() {
    return this.slot.selectedOptions[0]?.dataset.epoch || null
  }
}

target(MeetupFormElement.prototype, "location")
target(MeetupFormElement.prototype, "slot")

controller(MeetupFormElement)

export default MeetupFormElement
