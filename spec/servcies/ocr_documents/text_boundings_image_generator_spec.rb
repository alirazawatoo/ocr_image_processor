# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OcrDocuments::TextBoundingsImageGenerator, type: :service do
  let(:ocr_document) { create(:ocr_document) }

  before do
    create(:text_extraction, ocr_document:, word: 'TOTAL', x_start: 60, y_start: 414, x_end: 150, y_end: 444)
  end

  it 'attaches a PNG with the same dimensions as the upload' do
    described_class.call(ocr_document.id)

    marked = ocr_document.reload.generated_image
    expect(marked).to be_attached
    expect(marked.content_type).to eq('image/png')

    image = Magick::Image.from_blob(marked.download).first
    expect([image.columns, image.rows]).to eq([960, 520])
  end

  it 'does not leave files in the application root' do
    expect { described_class.call(ocr_document.id) }.not_to(change { Dir.children(Rails.root).sort })
  end

  it 'does nothing for an unknown document' do
    expect(described_class.call(0)).to be_nil
  end
end
