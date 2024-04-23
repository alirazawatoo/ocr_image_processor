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

  describe 'GET /ocr_documents/:id' do
    it 'shows the uploaded image' do
      document = create(:ocr_document)

      get ocr_document_path(document)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Uploaded image')
    end

    it 'redirects home with a message for an unknown id' do
      get ocr_document_path(0)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('That document could not be found.')
    end
  end

  describe 'GET /ocr_documents/:id/search' do
    let(:document) { create(:ocr_document) }

    before do
      create(:text_extraction, ocr_document: document, word: 'TOTAL', x_start: 60, y_start: 414, x_end: 150, y_end: 444)
    end

    it 'returns match boxes as JSON' do
      get search_ocr_document_path(document), params: { query: 'tot' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([{ 'x_start' => 60, 'y_start' => 414, 'x_end' => 114, 'y_end' => 444 }])
    end

    it 'returns an empty list when nothing matches' do
      get search_ocr_document_path(document), params: { query: 'pencil' }

      expect(response.parsed_body).to eq([])
    end

    it 'rejects an empty or overlong query' do
      get search_ocr_document_path(document), params: { query: ' ' }
      expect(response).to have_http_status(:unprocessable_content)

      get search_ocr_document_path(document), params: { query: 'x' * 101 }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'answers 404 JSON for an unknown document' do
      get search_ocr_document_path(0), params: { query: 'total' }

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq('error' => 'Document not found.')
    end
  end
end
