# frozen_string_literal: true

module OcrDocuments
  # Runs Tesseract on the stored upload and replaces the document's word boxes.
  class ExtractTextService < BaseService
    BOX_ATTRIBUTES = %i[word confidence x_start y_start x_end y_end].freeze

    def call
      return if @ocr_document.blank?

      words = recognized_words

      OcrDocument.transaction do
        # Replacing rather than appending keeps a retried job from duplicating words.
        @ocr_document.text_extractions.delete_all
        @ocr_document.text_extractions.create!(words) if words.any?
        @ocr_document.update!(hocr_processed_at: Time.current)
      end
    end

    private

    # Tesseract reads a local temp copy of the blob. RTesseract passes the path
    # as a separate argv entry (Open3 without a shell), so no quoting is involved.
    def recognized_words
      boxes = @ocr_document.original_image.open { |file| RTesseract.new(file.path).to_box }
      boxes.filter_map do |box|
        box.slice(*BOX_ATTRIBUTES) if box[:word].present?
      end
    end
  end
end
