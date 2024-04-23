import { Controller } from "@hotwired/stimulus"

// Draws search matches over the original image on a canvas that tracks its size.
export default class extends Controller {
  static targets = ["query", "image", "canvas", "status"]
  static values = { url: String }

  connect() {
    this.matches = []
    this.redraw = () => this.drawMatches()
    window.addEventListener("resize", this.redraw)
    if (!this.imageTarget.complete) this.imageTarget.addEventListener("load", this.redraw, { once: true })
  }

  disconnect() {
    window.removeEventListener("resize", this.redraw)
  }

  async search(event) {
    event.preventDefault()
    const query = this.queryTarget.value.trim()
    if (query === "") return

    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("query", query)
    this.statusTarget.textContent = "Searching…"

    try {
      const response = await fetch(url, { headers: { Accept: "application/json" } })
      const body = await response.json()
      if (!response.ok) throw new Error(body.error || "Search failed.")

      this.matches = body
      this.statusTarget.textContent = this.summary(query, body.length)
    } catch (error) {
      this.matches = []
      this.statusTarget.textContent = error.message
    }
    this.drawMatches()
  }

  summary(query, count) {
    if (count === 0) return `No words contain “${query}”.`
    return `${count} ${count === 1 ? "match" : "matches"} for “${query}”.`
  }

  drawMatches() {
    const image = this.imageTarget
    const canvas = this.canvasTarget
    canvas.width = image.clientWidth
    canvas.height = image.clientHeight
    canvas.style.width = `${image.clientWidth}px`
    canvas.style.height = `${image.clientHeight}px`

    const ctx = canvas.getContext("2d")
    ctx.clearRect(0, 0, canvas.width, canvas.height)
    if (!image.naturalWidth) return

    const scaleX = image.clientWidth / image.naturalWidth
    const scaleY = image.clientHeight / image.naturalHeight
    ctx.fillStyle = "rgba(250, 204, 21, 0.45)"
    ctx.strokeStyle = "#a16207"
    ctx.lineWidth = 2

    this.matches.forEach(({ x_start, y_start, x_end, y_end }) => {
      const x = x_start * scaleX
      const y = y_start * scaleY
      const width = (x_end - x_start) * scaleX
      const height = (y_end - y_start) * scaleY
      ctx.fillRect(x, y, width, height)
      ctx.strokeRect(x, y, width, height)
    })
  }
}
