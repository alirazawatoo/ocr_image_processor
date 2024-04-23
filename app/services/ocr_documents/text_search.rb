# frozen_string_literal: true

module OcrDocuments
  class TextSearch < BaseService
    def initialize(ocr_document_id, query)
      super(ocr_document_id)
      @query = query.downcase
    end

    def call
      return if @ocr_document.blank?

      search_and_map_coordinates
    end

    private

    def find_extractions_containing_query
      @ocr_document.text_extractions.where('LOWER(word) LIKE ?', "%#{@query}%")
    end

    def search_and_map_coordinates
      return if @ocr_document.text_extractions.blank?

      find_extractions_containing_query.map do |text_extraction|
        map_coordinates(text_extraction)
      end
    end

    def map_coordinates(text_extraction)
      query_start_index = calculate_query_start_index(text_extraction)
      query_end_index = query_start_index + @query.length
      letter_width = calculate_letter_width(text_extraction)

      o_x_start = calculate_o_x_start(text_extraction, query_start_index, letter_width)
      o_x_end = o_x_start + ((query_end_index - query_start_index) * letter_width)

      { x_start: o_x_start, y_start: text_extraction[:y_start], x_end: o_x_end,
        y_end: text_extraction[:y_end] }
    end

    def calculate_query_start_index(text_extraction)
      text_extraction.word.downcase.index(@query)
    end

    def calculate_letter_width(text_extraction)
      (text_extraction[:x_end] - text_extraction[:x_start]) / text_extraction.word.length
    end

    def calculate_o_x_start(text_extraction, query_start_index, letter_width)
      text_extraction[:x_start] + (query_start_index * letter_width)
    end
  end
end
