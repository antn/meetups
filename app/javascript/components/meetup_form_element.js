import { controller, target, targets } from "@github/catalyst"

// Drives the two-step meetup form: the viewer first picks a day & time, then the
// available locations are revealed as clickable map cards. A booking is a
// (location, start-time) pair; once a time is chosen, locations already taken at
// that time are grayed out and can't be selected.
//
// Usage:
//   <meetup-form data-booked='["12:1757696400", …]'>   // "<location_id>:<epoch>"
//     <select data-target="meetup-form.slot" data-action="change:meetup-form#sync">
//       <option data-epoch="1757696400">…</option>
//     </select>
//     <p data-target="meetup-form.locationHint">Pick a time first…</p>
//     <div data-target="meetup-form.locationGrid">
//       <label data-target="meetup-form.locationCard">
//         <input type="radio" data-target="meetup-form.locationInput"
//                data-action="change:meetup-form#sync" value="12">
//       </label>
//     </div>
//   </meetup-form>
class MeetupFormElement extends HTMLElement {
  connectedCallback() {
    this.booked = new Set(JSON.parse(this.dataset.booked || "[]"))
    this.sync()
  }

  sync() {
    const slotEpoch = this.selectedEpoch()
    const locationId = this.selectedLocation()?.value
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

    // The location picker only appears once a time is chosen.
    const hasSlot = Boolean(slotEpoch)
    this.locationHint.hidden = hasSlot
    this.locationGrid.hidden = !hasSlot

    // Disable the location cards already taken at the chosen time.
    this.locationInput.forEach((input) => {
      const booked = hasSlot && this.booked.has(`${input.value}:${slotEpoch}`)
      input.disabled = booked
      const card = input.closest("label")
      card.classList.toggle("pointer-events-none", booked)
      card.classList.toggle("opacity-40", booked)
    })

    // If a selection just became disabled (e.g. changing the time into a clash),
    // clear it and re-run so the freed side opens back up.
    let cleared = false
    const location = this.selectedLocation()
    if (location?.disabled) {
      location.checked = false
      cleared = true
    }
    if (this.slot.selectedOptions[0]?.disabled) {
      this.slot.value = ""
      cleared = true
    }
    if (cleared) this.sync()
  }

  selectedLocation() {
    return this.locationInput.find((input) => input.checked)
  }

  selectedEpoch() {
    return this.slot.selectedOptions[0]?.dataset.epoch || null
  }
}

target(MeetupFormElement.prototype, "slot")
target(MeetupFormElement.prototype, "locationHint")
target(MeetupFormElement.prototype, "locationGrid")
targets(MeetupFormElement.prototype, "locationInput")

controller(MeetupFormElement)

export default MeetupFormElement
