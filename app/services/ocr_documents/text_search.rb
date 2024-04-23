# frozen_string_literal: true

module OcrDocuments
  # Finds words containing the query and estimates the pixel span of the match
  # inside each word box, assuming roughly even letter widths.
  class TextSearch < BaseService
    def initialize(ocr_document_id, query)
      super(ocr_document_id)
      @query = query.to_s.strip.downcase
    end

    def call
      return [] if @ocr_document.blank? || @query.empty?

      matching_extractions.filter_map { |text_extraction| match_box(text_extraction) }
    end

    private

    def matching_extractions
      pattern = "%#{OcrDocument.sanitize_sql_like(@query)}%"
      @ocr_document.text_extractions.where('LOWER(word) LIKE ?', pattern).order(:y_start, :x_start)
    end

    def match_box(text_extraction)
      word = text_extraction.word.downcase
      # Postgres LOWER and Ruby downcase can disagree on some Unicode letters.
      start_index = word.index(@query)
      return if start_index.nil?

      x_start, x_end = match_span(text_extraction, start_index, word.length)
      { x_start:, y_start: text_extraction.y_start, x_end:, y_end: text_extraction.y_end }
    end

    def match_span(text_extraction, start_index, word_length)
      letter_width = (text_extraction.x_end - text_extraction.x_start).fdiv(word_length)
      x_start = text_extraction.x_start + (start_index * letter_width)
      [x_start.floor, (x_start + (@query.length * letter_width)).ceil]
    end
  end
end
