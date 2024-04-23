# frozen_string_literal: true

class OcrDocument < ApplicationRecord
  has_many :text_extractions, dependent: :destroy
  has_one_attached :original_image
  has_one_attached :generated_image

  validate :acceptable_image

  after_commit :process_on_after_create_commit, on: :create

  def original_image_path
    Rails.application.routes.url_helpers.url_for(original_image)
  end

  private

  def process_on_after_create_commit
    OcrDocuments::ExtractHocrDataJob.perform_later(id, true)
  end

  def acceptable_image
    return unless original_image.attached?

    errors.add(:original_image, 'is too big') unless original_image.blob.byte_size <= 1.megabyte

    return if ['image/png'].include?(original_image.content_type)

    errors.add(:original_image, 'must be a PNG')
  end
end
