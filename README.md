# OCR Image Processor

A Rails application for uploading PNG documents, extracting text with Tesseract, searching recognized content, and generating a marked image with matching bounding boxes.

## Processing pipeline

```text
image upload -> OCR extraction job -> text + hOCR bounds
                                  -> search terms
                                  -> marked image generation
```

Service objects isolate text extraction, search, bounding-box drawing, and image generation. Active Storage manages uploads; background jobs handle extraction and marked-image work.

## Local setup

Requirements: Ruby 3.0.2, PostgreSQL, Redis, ImageMagick, and Tesseract.

```bash
git clone https://github.com/alirazawatoo/ocr_image_processor.git
cd ocr_image_processor
bundle install
rails db:create db:migrate
bundle exec rails server
```

Start the configured background-job processor and Redis before uploading documents.

## Verification boundaries

- OCR quality varies with resolution, orientation, language, typography, and image noise.
- Extracted text and bounding boxes should be reviewed rather than treated as authoritative.
- Uploaded documents can contain sensitive data; production use needs access controls, retention rules, and secure storage.
- Model, controller, and service specs exist.
