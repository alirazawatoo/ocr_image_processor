# frozen_string_literal: true

module OcrDocuments
  class ExtractTextService < BaseService
    def call
      return if @ocr_document.blank?

      @ocr_document.text_extractions.create(RTesseract.new(@ocr_document.original_image_path).to_box)
      @ocr_document.update(hocr_processed_at: Time.current)
    end
  end
end
