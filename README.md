# OCR Image Processor

A small Rails app that reads a PNG with Tesseract, remembers where every word sits on the page, and lets you search the image. Matches are highlighted on the original. A second copy of the image comes back with a box drawn around every word Tesseract found, which shows at a glance what the OCR saw and what it missed.

It suits checking scans before trusting their text, for example finding a total on a receipt, confirming a reference number on a form, or seeing why a line was not recognised.

![Searching a synthetic receipt for "ink": the match is highlighted on the original, and the marked copy outlines all 19 recognised words](docs/screenshots/search-desktop.png)

## How it works

```mermaid
flowchart LR
  U[Browser] -- PNG upload --> W[Rails web]
  W -- header check: type, 1 MB, 6000 px, 25 MP --> S[(Active Storage)]
  W -- enqueue --> R[(Redis)]
  R --> K[Sidekiq worker]
  K -- ExtractHocrDataJob --> T[Tesseract]
  T -- word + box + confidence --> P[(Postgres)]
  K -- GenerateMarkedImageJob --> M[RMagick draws boxes]
  M --> S
  U -- search?query= --> W
  W -- LIKE match, sub-word span --> U
```

1. **Upload.** `OcrDocument` validates the file before it is stored. It must be present, be a real PNG (checked by its signature, not the browser's label), be at most 1 MB, and its header must declare no more than 6000 px on a side and 25 megapixels. The header is read without decoding pixels, so a small file that would expand into gigabytes is refused before ImageMagick or Tesseract open it.
2. **Read.** `ExtractHocrDataJob` downloads the blob to a temp file and runs `tesseract` on it through `rtesseract`, which calls `Open3` with an argument list and never a shell string. Each word, its confidence and its bounding box become a `TextExtraction` row. A re-run replaces the rows instead of adding to them.
3. **Mark.** `GenerateMarkedImageJob` opens the same blob with the PNG decoder pinned, outlines every word in one draw pass, and attaches the result. Nothing is written to the app directory.
4. **Search.** `GET /ocr_documents/:id/search?query=` finds words that contain the query (case-insensitive, with `%` and `_` treated literally). It narrows each box to the matched letters by assuming even letter widths. The Stimulus controller scales those boxes onto a canvas over the original image.

While the jobs run, the page shows a status badge and refreshes itself every few seconds. If Tesseract or ImageMagick keeps failing, each job retries twice with back-off. It then stores a short message, which the page shows in place of the spinner.

| Upload | While processing | Phone |
| --- | --- | --- |
| ![Upload page](docs/screenshots/upload-desktop.png) | ![Processing state](docs/screenshots/processing-desktop.png) | ![Search on a phone](docs/screenshots/search-mobile.png) |

All screenshots use `spec/fixtures/files/sample_receipt.png`, a receipt generated for the tests. It contains no real data.

## Run it with Docker Compose

Needs Docker with Compose v2. This builds the production image (Ruby 3.4.12, Tesseract 5 and ImageMagick 6 from Debian bookworm) and starts the web server, a Sidekiq worker, `postgres:17` and `redis:7`.

```bash
cp .env.example .env
# put a key in .env:
sed -i.bak "s/^SECRET_KEY_BASE=.*/SECRET_KEY_BASE=$(openssl rand -hex 64)/" .env && rm .env.bak
# and change POSTGRES_PASSWORD from change-me (letters and digits)
docker compose up --build --wait
```

Open <http://localhost:3000> (or the `APP_PORT` you set), upload a PNG, and the document page fills in once the worker is done, usually within a couple of seconds for a page of text. `docker compose down` stops the stack. Add `-v` to also delete the database, Redis and uploaded files.

The containers run as an unprivileged `rails` user (uid 1000). The web container's entrypoint runs `db:prepare` on start, and `/up` answers 200 for health checks.

### Configuration

Everything is read from the environment. `.env.example` lists the values Compose uses:

| Variable | Purpose |
| --- | --- |
| `SECRET_KEY_BASE` | Signs cookies and the document links. Required in production. |
| `POSTGRES_PASSWORD` | Password for the bundled Postgres, also placed into `DATABASE_URL`. |
| `DATABASE_URL` | Set by Compose. Outside Compose it overrides `config/database.yml`. |
| `REDIS_URL` | Sidekiq's Redis. Defaults to `redis://localhost:6379/0`. |
| `FORCE_SSL` | Defaults to `true`. The Compose demo sets it to `false` to serve plain HTTP. |
| `ASSUME_SSL` | Set to `true` behind a proxy that terminates TLS. |

The repository has no Rails master key, and the app does not use encrypted credentials.

## Tests and lint

The suite has 64 RSpec examples covering models, services, jobs and requests. One example runs the real `tesseract` binary on the synthetic receipt and is skipped if Tesseract is missing. RuboCop runs with the Rails and RSpec cops.

The specs need Postgres, Tesseract and the ImageMagick headers. The simplest way to get them is a throwaway container:

```bash
docker network create ocr-test
docker run -d --rm --name ocr-test-db --network ocr-test -e POSTGRES_PASSWORD=test postgres:17
docker run --rm --network ocr-test -v "$PWD":/src:ro -e RAILS_ENV=test \
  -e DATABASE_URL=postgres://postgres:test@ocr-test-db/ocr_test ruby:3.4.12-slim-bookworm bash -c '
    apt-get update -qq &&
    apt-get install -y --no-install-recommends build-essential libpq-dev libyaml-dev pkg-config \
      libmagickwand-dev tesseract-ocr tesseract-ocr-eng >/dev/null &&
    cp -a /src /app && cd /app && bundle install --quiet &&
    bin/rails db:prepare && bundle exec rspec && bundle exec rubocop'
docker rm -f ocr-test-db && docker network rm ocr-test
```

With Ruby 3.4.12, PostgreSQL, Redis, Tesseract and ImageMagick 6 installed locally, the usual `bin/setup`, `bin/rails server` and `bundle exec sidekiq` work too.

## API

The search endpoint returns JSON. Coordinates are pixels in the original image. These responses were captured from the Compose stack using the sample receipt:

```http
GET /ocr_documents/eyJfcmFpbHMi...--b96e0a09.../search?query=total

HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8

[{"x_start":61,"y_start":418,"x_end":149,"y_end":440}]
```

```http
GET /ocr_documents/eyJfcmFpbHMi...--b96e0a09.../search?query=pen

[{"x_start":225,"y_start":273,"x_end":273,"y_end":296}]
```

A query with no matches returns `[]`. An empty query or one over 100 characters returns 422. An unknown or tampered document id returns 404 with `{"error":"Document not found."}`.

## Design notes

- **Links are the only access control.** There are no accounts, so documents are addressed by a signed id (`find_signed`) rather than `/ocr_documents/1, 2, 3…`. Anyone holding a link can still open the document. Treat links like shared-folder URLs.
- **PNG only, on purpose.** Accepting one format keeps the header check exact and lets the marking job pin ImageMagick's decoder, so ImageMagick never guesses the format of an uploaded file.
- **In-memory marking.** The marked image is rendered with `to_blob` and attached directly. An earlier version wrote `temp_image_with_boxes.png` into the app root on every run.
- **Sub-word highlighting is an estimate.** Tesseract gives one box per word. The search splits that box evenly across the letters, which is close for monospaced text and rough for proportional fonts.

## Limitations

- Only English language data (`tesseract-ocr-eng`) is installed in the image.
- Uploads go to local disk (`storage/`, a named volume under Compose). There is no deletion or retention policy, so don't use this as-is for sensitive documents.
- OCR quality depends on resolution, contrast and orientation. The marked copy is the quickest way to see what was missed.

## License

MIT, see [LICENSE](LICENSE).
