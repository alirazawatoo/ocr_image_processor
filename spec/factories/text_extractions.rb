# frozen_string_literal: true

FactoryBot.define do
  factory :text_extraction do
    word { Faker::Lorem.word }
    confidence { Faker::Number.between(from: 0, to: 100) }
    x_start { Faker::Number.between(from: 0, to: 100) }
    y_start { Faker::Number.between(from: 0, to: 100) }
    x_end { Faker::Number.between(from: 0, to: 100) }
    y_end { Faker::Number.between(from: 0, to: 100) }
    association :ocr_document
  end
end
