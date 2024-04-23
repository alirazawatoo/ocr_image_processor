# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TextExtraction, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:ocr_document) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:word) }
    it { is_expected.to validate_presence_of(:confidence) }

    it 'keeps confidence a whole percentage' do
      expect(build(:text_extraction)).to validate_numericality_of(:confidence)
        .only_integer.is_greater_than_or_equal_to(0)
        .is_less_than_or_equal_to(100)
    end

    it { is_expected.to validate_presence_of(:x_start) }
    it { is_expected.to validate_presence_of(:y_start) }
    it { is_expected.to validate_presence_of(:x_end) }
    it { is_expected.to validate_presence_of(:y_end) }
    it { is_expected.to validate_numericality_of(:x_start).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:y_start).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:x_end).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:y_end).only_integer.is_greater_than_or_equal_to(0) }
  end
end
