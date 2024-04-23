# frozen_string_literal: true

module OcrDocuments
  class BaseService < ApplicationService
    def initialize(ocr_document_id)
      super()
      @ocr_document = OcrDocument.find_by(id: ocr_document_id)
    end
  end
end
