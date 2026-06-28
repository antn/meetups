import { controller, target, targets } from "@github/catalyst"

// Positions a "current time" marker line across the schedule, the way calendars
// do. Rows are variable height, so we locate the row for the current hour and
// offset into it by the minute fraction of that row's measured height.
//
// Usage:
//   <time-marker class="relative block">
//     <ol>
//       <li data-targets="time-marker.rows" data-hour="10">…</li>
//       …
//     </ol>
//     <div data-target="time-marker.line" hidden>
//       <span data-target="time-marker.label"></span>…
//     </div>
//   </time-marker>
class TimeMarkerElement extends HTMLElement {
  connectedCallback() {
    this.reposition()
    this._timer = setInterval(() => this.reposition(), 60 * 1000)
    this._onResize = () => this.reposition()
    window.addEventListener("resize", this._onResize)
  }

  disconnectedCallback() {
    clearInterval(this._timer)
    window.removeEventListener("resize", this._onResize)
  }

  reposition() {
    // Skip while the panel is hidden — offsets can't be measured.
    if (this.offsetParent === null || !this.rows.length) return

    const hours = this.rows.map((row) => Number(row.dataset.hour))
    const openHour = Math.min(...hours)
    const lastHour = Math.max(...hours)

    const now = new Date()
    let hour = now.getHours()
    let minutes = now.getMinutes()

    // Mockup: clamp "now" into the schedule window so the marker stays visible.
    // In production, hide the marker instead when outside the booking window.
    if (hour < openHour) {
      hour = openHour
      minutes = 0
    } else if (hour > lastHour) {
      hour = lastHour
      minutes = 59
    }

    const row = this.rows.find((r) => Number(r.dataset.hour) === hour)
    if (!row) return

    const top = row.offsetTop + (minutes / 60) * row.offsetHeight
    this.line.style.top = `${top}px`
    this.line.hidden = false
    this.label.textContent = now.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })
  }
}

target(TimeMarkerElement.prototype, "line")
target(TimeMarkerElement.prototype, "label")
targets(TimeMarkerElement.prototype, "rows")

controller(TimeMarkerElement)

export default TimeMarkerElement
