# frozen_string_literal: true

# OcrDocumentsController handles the creation, display, and search of OCR documents.
class OcrDocumentsController < ApplicationController
  before_action :find_ocr_document, only: %i[show search]

  def new
    @ocr_document = OcrDocument.new
  end

  def create
    @ocr_document = OcrDocument.new(ocr_document_params)
    if @ocr_document.save
      redirect_to @ocr_document, notice: 'Ocr document processing has been started.'
    else
      flash.now[:alert] = 'Failed to save the OCR document.'
      render :new
    end
  end

  def show; end

  def search
    @search_query = params[:query]

    respond_to do |format|
      format.json do
        if @ocr_document.present? && @search_query.present?
          render json: OcrDocuments::TextSearch.call(@ocr_document.id, @search_query)
        else
          render json: { error: 'No data found' }, status: :unprocessable_entity
        end
      end
    end
  end

  private

  def find_ocr_document
    @ocr_document = OcrDocument.find_by(id: params[:id])

    return if @ocr_document.present?

    flash.now[:alert] = 'OCR document not found.'
    redirect_to root_path
  end

  def ocr_document_params
    params.require(:ocr_document).permit(:original_image)
  end
end
