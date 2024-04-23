# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OCR documents', type: :request do
  describe 'GET /' do
    it 'shows the upload form' do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('type="file"')
    end
  end

  describe 'POST /ocr_documents' do
    it 'stores the upload, queues extraction and redirects to the document' do
      expect do
        post ocr_documents_path, params: { ocr_document: { original_image: sample_receipt_upload } }
      end.to change(OcrDocument, :count).by(1)

      expect(response).to redirect_to(ocr_document_path(OcrDocument.last))
      expect(OcrDocuments::ExtractHocrDataJob).to have_been_enqueued.with(OcrDocument.last.id, true)
    end

    it 'answers 422 with the reason when the file is rejected' do
      post ocr_documents_path, params: { ocr_document: { original_image: png_upload(png_bytes(width: 9_000, height: 9_000)) } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('must be at most 6000')
      expect(OcrDocument.count).to eq(0)
    end

    it 'answers 422 instead of 400 when no file was chosen' do
      post ocr_documents_path, params: {}

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('must be chosen')
    end
  end
end
