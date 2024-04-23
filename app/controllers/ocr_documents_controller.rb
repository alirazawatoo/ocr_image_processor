# frozen_string_literal: true

# Upload a PNG, watch it being processed, and search its recognised words.
class OcrDocumentsController < ApplicationController
  MAX_QUERY_LENGTH = 100

  before_action :find_ocr_document, only: %i[show search]

  def new
    @ocr_document = OcrDocument.new
  end

  def create
    @ocr_document = OcrDocument.new(ocr_document_params)
    if @ocr_document.save
      redirect_to @ocr_document, notice: 'Upload received. Text extraction has started.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def show; end

  def search
    query = params[:query].to_s.strip

    if query.empty? || query.length > MAX_QUERY_LENGTH
      render json: { error: "Search for 1 to #{MAX_QUERY_LENGTH} characters." }, status: :unprocessable_content
    else
      render json: OcrDocuments::TextSearch.call(@ocr_document.id, query)
    end
  end

  private

  def find_ocr_document
    @ocr_document = OcrDocument.from_link(params[:id])
    return if @ocr_document

    respond_to do |format|
      format.html { redirect_to root_path, alert: 'That document could not be found.' }
      format.json { render json: { error: 'Document not found.' }, status: :not_found }
    end
  end

  def ocr_document_params
    params.fetch(:ocr_document, {}).permit(:original_image)
  end
end
