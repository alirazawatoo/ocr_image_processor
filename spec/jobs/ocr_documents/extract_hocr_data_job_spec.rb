# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OcrDocuments::ExtractHocrDataJob, type: :job do
  include ActiveJob::TestHelper

  let!(:ocr_document) { create(:ocr_document) }

  it 'extracts text and queues the marked image' do
    allow(OcrDocuments::ExtractTextService).to receive(:call)

    described_class.perform_now(ocr_document.id)

    expect(OcrDocuments::ExtractTextService).to have_received(:call).with(ocr_document.id)
    expect(OcrDocuments::GenerateMarkedImageJob).to have_been_enqueued.with(ocr_document.id)
  end

  it 'skips the marked image when asked to' do
    allow(OcrDocuments::ExtractTextService).to receive(:call)

    described_class.perform_now(ocr_document.id, generate_marked_image: false)

    expect(OcrDocuments::GenerateMarkedImageJob).not_to have_been_enqueued
  end

  it 'does nothing for a deleted document' do
    allow(OcrDocuments::ExtractTextService).to receive(:call)

    described_class.perform_now(0)

    expect(OcrDocuments::ExtractTextService).not_to have_received(:call)
  end

  it 'retries Tesseract errors, then records a readable failure' do
    allow(OcrDocuments::ExtractTextService).to receive(:call).and_raise(RTesseract::Error, 'read_image failed')

    perform_enqueued_jobs(only: described_class) { described_class.perform_later(ocr_document.id) }

    expect(OcrDocuments::ExtractTextService).to have_received(:call).exactly(3).times
    expect(ocr_document.reload.processing_error).to eq('Text could not be read from this image.')
    expect(ocr_document).to be_failed
  end

  it 'records a failure without retrying when the stored file is gone' do
    allow(OcrDocuments::ExtractTextService).to receive(:call).and_raise(ActiveStorage::FileNotFoundError)

    perform_enqueued_jobs(only: described_class) { described_class.perform_later(ocr_document.id) }

    expect(OcrDocuments::ExtractTextService).to have_received(:call).once
    expect(ocr_document.reload.processing_error).to eq('The uploaded file is missing from storage.')
  end
end
