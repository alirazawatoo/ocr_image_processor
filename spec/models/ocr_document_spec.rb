# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OcrDocument, type: :model do
  describe 'associations' do
    it { should have_many(:text_extractions).dependent(:destroy) }
    it { should have_one_attached(:original_image) }
    it { should have_one_attached(:generated_image) }
  end

  describe 'callbacks' do
    describe 'after_create_commit' do
      let(:ocr_document) { create(:ocr_document) }

      it 'queues ExtractHocrDataJob' do
        expect(OcrDocuments::ExtractHocrDataJob).to receive(:perform_later).with(ocr_document.id, true)
        ocr_document.run_callbacks(:commit)
      end
    end
  end

  describe '#original_image_path' do
    let(:ocr_document) { create(:ocr_document) }

    it 'returns the URL for the attached original image' do
      expect(ocr_document.original_image_path).to eq(
        Rails.application.routes.url_helpers.url_for(ocr_document.original_image)
      )
    end
  end
end
