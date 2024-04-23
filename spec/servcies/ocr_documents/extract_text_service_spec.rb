# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OcrDocuments::ExtractTextService, type: :service do
  describe '#call' do
    let(:ocr_document) { create(:ocr_document) }
    let(:service) { described_class.new(ocr_document.id) }

    context 'when the OCR document is valid' do
      before do
        allow(RTesseract).to receive_message_chain(:new, :to_box).and_return(attributes_for_list(:text_extraction, 4))
      end

      it 'creates text extractions for the OCR document' do
        expect { service.call }.to change { ocr_document.text_extractions.count }.by(4)
      end

      it 'updates the hocr_processed_at attribute of the OCR document' do
        expect { service.call }.to(change { ocr_document.reload.hocr_processed_at })
      end
    end

    context 'when the OCR document is not found' do
      let(:invalid_service) { described_class.new(999) }

      it 'does not raise an error' do
        expect { invalid_service.call }.not_to raise_error
      end

      it 'does not create text extractions' do
        expect { invalid_service.call }.not_to(change { TextExtraction.count })
      end

      it 'does not update the hocr_processed_at attribute' do
        expect { invalid_service.call }.not_to(change { ocr_document.reload.hocr_processed_at })
      end
    end
  end
end
