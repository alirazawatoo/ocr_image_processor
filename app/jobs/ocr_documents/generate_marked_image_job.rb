# frozen_string_literal: true

module OcrDocuments
  class GenerateMarkedImageJob < ApplicationJob
    queue_as :default

    def perform(ocr_document_id)
      ocr_document = OcrDocument.find_by(id: ocr_document_id)

      return if ocr_document.blank?

      TextBoundingsImageGenerator.call(ocr_document.id)
    end
  end
end
