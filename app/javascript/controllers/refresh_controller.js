import { Controller } from "@hotwired/stimulus"

// Reloads the page every few seconds while background jobs are still running.
export default class extends Controller {
  static values = { interval: { type: Number, default: 3000 } }

  connect() {
    this.timer = setTimeout(() => window.Turbo.visit(window.location.href, { action: "replace" }), this.intervalValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }
}
