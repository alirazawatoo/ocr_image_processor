# frozen_string_literal: true

module OcrDocuments
  class GenerateMarkedImageJob < ApplicationJob
    include FailureRecording

    queue_as :default

    retry_on Magick::ImageMagickError, wait: :polynomially_longer, attempts: 3 do |job, error|
      job.record_failure('The marked image could not be drawn.', error)
    end

    discard_on ActiveStorage::FileNotFoundError do |job, error|
      job.record_failure('The uploaded file is missing from storage.', error)
    end

    def perform(ocr_document_id)
      ocr_document = OcrDocument.find_by(id: ocr_document_id)
      return if ocr_document.blank?

      TextBoundingsImageGenerator.call(ocr_document.id)
    end
  end
end
