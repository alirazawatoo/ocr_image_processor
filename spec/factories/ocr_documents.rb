# frozen_string_literal: true

FactoryBot.define do
  factory :ocr_document do
    original_image do
      Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/sample_receipt.png'), 'image/png')
    end
  end
end
