# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OcrDocuments::GenerateMarkedImageJob, type: :job do
  include ActiveJob::TestHelper

  let!(:ocr_document) { create(:ocr_document) }

  it 'attaches the marked image' do
    described_class.perform_now(ocr_document.id)

    expect(ocr_document.reload.generated_image).to be_attached
  end

  it 'retries ImageMagick errors, then records a readable failure' do
    allow(OcrDocuments::TextBoundingsImageGenerator)
      .to receive(:call).and_raise(Magick::ImageMagickError, 'no decode delegate')

    perform_enqueued_jobs(only: described_class) { described_class.perform_later(ocr_document.id) }

    expect(OcrDocuments::TextBoundingsImageGenerator).to have_received(:call).exactly(3).times
    expect(ocr_document.reload.processing_error).to eq('The marked image could not be drawn.')
  end
end
