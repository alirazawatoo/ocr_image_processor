# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OcrDocuments::TextSearch, type: :service do
  let(:ocr_document) { create(:ocr_document) }

  def add_word(word, x_start:, x_end:, y_start: 10, y_end: 30)
    create(:text_extraction, ocr_document:, word:, x_start:, x_end:, y_start:, y_end:)
  end

  it 'narrows the box to the matched letters' do
    add_word('Stationery', x_start: 100, x_end: 200)

    expect(described_class.call(ocr_document.id, 'ion')).to eq(
      [{ x_start: 140, y_start: 10, x_end: 170, y_end: 30 }]
    )
  end

  it 'matches regardless of case' do
    add_word('TOTAL', x_start: 0, x_end: 50)

    expect(described_class.call(ocr_document.id, 'total').size).to eq(1)
  end

  it 'keeps fractional letter widths instead of truncating them to zero' do
    add_word('wide', x_start: 0, x_end: 3)

    expect(described_class.call(ocr_document.id, 'de')).to eq([{ x_start: 1, y_start: 10, x_end: 3, y_end: 30 }])
  end

  it 'treats % and _ as literal characters' do
    add_word('12.50', x_start: 0, x_end: 50)
    add_word('50%', x_start: 60, x_end: 90)

    expect(described_class.call(ocr_document.id, '%').size).to eq(1)
    expect(described_class.call(ocr_document.id, '_')).to eq([])
  end

  it 'returns an empty list when nothing matches or the document is unknown' do
    add_word('pen', x_start: 0, x_end: 30)

    expect(described_class.call(ocr_document.id, 'pencil')).to eq([])
    expect(described_class.call(0, 'pen')).to eq([])
    expect(described_class.call(ocr_document.id, '   ')).to eq([])
  end
end
