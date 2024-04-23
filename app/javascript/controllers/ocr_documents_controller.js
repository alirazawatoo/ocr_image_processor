import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["params"];
  coord = [];
  image = document.getElementById('original-image');
  canvas = document.getElementById('imageCanvas');

  connect() {
    window.addEventListener('resize', () => {
      this.redrawRectangles(this.image, this.canvas);
    });
  }

  search(event) {
    event.preventDefault();
    const ocrDocumentId = event.target.dataset.ocrDocumentId;
    const query = this.paramsTarget.value;

    fetch(`/ocr_documents/${ocrDocumentId}/search?query=${query}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    })
    .then(response => response.json())
    .then(data => {
      this.drawRectangles(this.image, this.canvas, data);
    });
  }

  resizeCanvas(img, canvas) {
    canvas.style.position = 'absolute';
    canvas.style.left = img.offsetLeft; + 'px';
    canvas.style.top = img.offsetTop; + 'px';

    canvas.width = img.width;
    canvas.height = img.height;
    canvas.style.width = img.width + 'px';
    canvas.style.height = img.height + 'px';
    canvas.style.top = img.offsetTop + 'px';
    canvas.style.left = img.offsetLeft + 'px';
  }

  redrawRectangles(img, canvas) {
    this.resizeCanvas(img, canvas);
    this.drawRectangles(this.image, this.canvas);
  }

  drawRectangles(image, canvas, coordinates = this.coord) {
    this.coord = coordinates
    const ctx = canvas.getContext('2d');

    this.resizeCanvas(image, canvas);

    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.strokeStyle = 'blue';

    coordinates.forEach(coord => {
      const x_start = (coord.x_start / image.naturalWidth) * image.width;
      const y_start = (coord.y_start / image.naturalHeight) * image.height;
      const x_end = (coord.x_end / image.naturalWidth) * image.width;
      const y_end = (coord.y_end / image.naturalHeight) * image.height;

      ctx.strokeRect(x_start, y_start, x_end - x_start, y_end - y_start);
    });
  }
}
