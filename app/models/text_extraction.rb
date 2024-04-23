# frozen_string_literal: true

class TextExtraction < ApplicationRecord
  belongs_to :ocr_document

  validates :word, presence: true
  validates :confidence, presence: true,
                         numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :x_start, :y_start, :x_end, :y_end, presence: true,
                                                numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
