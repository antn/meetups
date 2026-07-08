import { controller, targets } from "@github/catalyst"

// Day selector for the meetup schedule.
//
// Usage in a view:
//   <day-tabs>
//     <button data-targets="day-tabs.tabs" data-action="click:day-tabs#select" data-index="0" data-date="2026-07-24">…</button>
//     …
//     <div data-targets="day-tabs.panels">…</div>
//     …
//   </day-tabs>
//
// Clicking a tab reveals the matching panel and highlights the active tab. The
// chosen day is also written to the URL (?day=<ISO date>) and onto any
// [data-day-link] (the tag-filter chips) so that a filter reload keeps the
// viewer on the same day.
class DayTabsElement extends HTMLElement {
  connectedCallback() {
    const current = this.tabs.find((tab) => tab.getAttribute("aria-selected") === "true") || this.tabs[0]
    if (current) this.syncLinks(current.dataset.date)
  }

  select(event) {
    const index = Number(event.currentTarget.dataset.index)
    const date = event.currentTarget.dataset.date

    this.tabs.forEach((tab, i) => {
      const active = i === index
      tab.setAttribute("aria-selected", active ? "true" : "false")
      tab.classList.toggle("bg-brand-purple", active)
      tab.classList.toggle("text-white", active)
      tab.classList.toggle("shadow-sm", active)
      tab.classList.toggle("bg-gray-100", !active)
      tab.classList.toggle("text-gray-600", !active)
      tab.classList.toggle("hover:bg-gray-200", !active)
    })

    this.panels.forEach((panel, i) => {
      panel.hidden = i !== index
    })

    const url = new URL(window.location)
    url.searchParams.set("day", date)
    window.history.replaceState({}, "", url)

    this.syncLinks(date)
  }

  // Point day-aware links (tag filters) at the currently selected day.
  syncLinks(date) {
    if (!date) return

    document.querySelectorAll("[data-day-link]").forEach((link) => {
      const url = new URL(link.href, window.location.origin)
      url.searchParams.set("day", date)
      link.href = url.toString()
    })
  }
}

targets(DayTabsElement.prototype, "tabs")
targets(DayTabsElement.prototype, "panels")

controller(DayTabsElement)

export default DayTabsElement
