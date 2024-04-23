# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OcrDocument, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:text_extractions).dependent(:delete_all) }
    it { is_expected.to have_one_attached(:original_image) }
    it { is_expected.to have_one_attached(:generated_image) }
  end

  describe 'callbacks' do
    describe 'after_create_commit' do
      let(:ocr_document) { create(:ocr_document) }

      it 'queues ExtractHocrDataJob' do
        expect(OcrDocuments::ExtractHocrDataJob).to have_been_enqueued.with(ocr_document.id)
      end
    end
  end

  describe 'upload validation' do
    def build_with(upload)
      described_class.new(original_image: upload)
    end

    it 'accepts the synthetic receipt PNG' do
      expect(build_with(sample_receipt_upload)).to be_valid
    end

    it 'requires an image' do
      document = described_class.new

      expect(document).not_to be_valid
      expect(document.errors[:original_image]).to include('must be chosen')
    end

    it 'rejects a non-PNG even when the browser claims image/png' do
      document = build_with(png_upload('%PDF-1.7 not an image', filename: 'scan.png'))

      expect(document).not_to be_valid
      expect(document.errors[:original_image]).to include('must be a PNG')
    end

    it 'rejects files over 1 MB' do
      big = png_bytes(width: 100, height: 100, idat: Random.new(1).bytes(1.megabyte + 1))
      document = build_with(png_upload(big))

      expect(document).not_to be_valid
      expect(document.errors[:original_image]).to include('must be 1 MB or smaller')
    end

    it 'rejects a small file that declares huge dimensions' do
      document = build_with(png_upload(png_bytes(width: 50_000, height: 50_000)))

      expect(document).not_to be_valid
      expect(document.errors[:original_image]).to include('must be at most 6000 × 6000 pixels')
    end

    it 'rejects a long strip that stays under the side limit but not the pixel limit' do
      document = build_with(png_upload(png_bytes(width: 6_000, height: 5_000)))

      expect(document).not_to be_valid
    end
  end

  describe 'document links' do
    let(:ocr_document) { create(:ocr_document) }

    it 'uses a signed token rather than the numeric id' do
      expect(ocr_document.to_param).not_to eq(ocr_document.id.to_s)
      expect(described_class.from_link(ocr_document.to_param)).to eq(ocr_document)
    end

    it 'finds nothing for a tampered or numeric token' do
      expect(described_class.from_link(ocr_document.id.to_s)).to be_nil
      expect(described_class.from_link("#{ocr_document.to_param}x")).to be_nil
    end
  end
end
