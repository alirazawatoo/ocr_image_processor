# frozen_string_literal: true

module OcrDocuments
  class ExtractHocrDataJob < ApplicationJob
    include FailureRecording

    queue_as :default

    # Tesseract failures are usually a bad image, but a retry covers a worker
    # being killed mid-run. After the last attempt the page shows the failure
    # instead of a spinner that never stops.
    retry_on RTesseract::Error, wait: :polynomially_longer, attempts: 3 do |job, error|
      job.record_failure('Text could not be read from this image.', error)
    end

    discard_on ActiveStorage::FileNotFoundError do |job, error|
      job.record_failure('The uploaded file is missing from storage.', error)
    end

    def perform(ocr_document_id, generate_marked_image = true)
      ocr_document = OcrDocument.find_by(id: ocr_document_id)
      return if ocr_document.blank?

      OcrDocuments::ExtractTextService.call(ocr_document.id)
      GenerateMarkedImageJob.perform_later(ocr_document.id) if generate_marked_image
    end
  end
end
