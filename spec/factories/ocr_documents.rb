# frozen_string_literal: true

FactoryBot.define do
  factory :ocr_document do
    original_image do
      Rack::Test::UploadedFile.new(File.open(File.join(Rails.root, 'app/assets/images/example_remit.png')))
    end
  end
end
