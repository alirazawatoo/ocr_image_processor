# frozen_string_literal: true

module OcrDocuments
  class ExtractHocrDataJob < ApplicationJob
    queue_as :default

    def perform(ocr_document_id, generate_marked_image)
      ocr_document = OcrDocument.find_by(id: ocr_document_id)

      return if ocr_document.blank?

      OcrDocuments::ExtractTextService.call(ocr_document.id)

      return unless generate_marked_image

      GenerateMarkedImageJob.perform_later(ocr_document_id)
    end
  end
end
