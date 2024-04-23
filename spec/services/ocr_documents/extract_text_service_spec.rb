# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OcrDocuments::ExtractTextService, type: :service do
  let(:ocr_document) { create(:ocr_document) }
  let(:service) { described_class.new(ocr_document.id) }

  context 'with Tesseract stubbed' do
    let(:boxes) { attributes_for_list(:text_extraction, 4) }
    let(:seen_paths) { [] }

    before do
      allow(RTesseract).to receive(:new) do |path|
        seen_paths << path
        instance_double(RTesseract, to_box: boxes)
      end
    end

    it 'creates text extractions for the OCR document' do
      expect { service.call }.to change { ocr_document.text_extractions.count }.by(4)
    end

    it 'updates the hocr_processed_at attribute of the OCR document' do
      expect { service.call }.to(change { ocr_document.reload.hocr_processed_at })
    end

    it 'hands Tesseract a local temp file rather than an app URL' do
      service.call

      expect(seen_paths.size).to eq(1)
      expect(seen_paths.first).to start_with(Dir.tmpdir)
      expect(seen_paths.first).not_to include('://')
    end

    it 'replaces earlier results when run again' do
      service.call

      expect { described_class.call(ocr_document.id) }.not_to(change { ocr_document.text_extractions.count })
    end

    it 'skips boxes with no recognised text' do
      boxes << boxes.first.merge(word: ' ')

      expect { service.call }.to change { ocr_document.text_extractions.count }.by(4)
    end
  end

  context 'when the OCR document is not found' do
    let(:invalid_service) { described_class.new(0) }

    it 'does not raise an error' do
      expect { invalid_service.call }.not_to raise_error
    end

    it 'does not create text extractions' do
      expect { invalid_service.call }.not_to change(TextExtraction, :count)
    end
  end

  context 'with the real Tesseract binary' do
    before do
      skip 'tesseract is not installed' unless system('tesseract', '--version', out: File::NULL, err: File::NULL)
    end

    it 'reads the words on the synthetic receipt' do
      service.call

      words = ocr_document.text_extractions.pluck(:word)
      expect(words).to include('HARBOR', 'STATIONERY', 'TOTAL', '23.75')
    end
  end
end
