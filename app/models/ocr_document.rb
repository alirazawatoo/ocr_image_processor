# frozen_string_literal: true

class OcrDocument < ApplicationRecord
  MAX_BYTE_SIZE = 1.megabyte
  MAX_SIDE = 6_000
  # A 1 MB PNG can still declare billions of pixels; cap the decoded size too.
  MAX_PIXELS = 25_000_000
  LINK_PURPOSE = :document_link

  has_many :text_extractions, dependent: :delete_all
  has_one_attached :original_image
  has_one_attached :generated_image

  validates :original_image, presence: { message: 'must be chosen' }
  validate :acceptable_image

  after_create_commit :enqueue_text_extraction

  # There are no accounts, so the link is the only access control: use a
  # signed id instead of the guessable sequential one.
  def to_param
    signed_id(purpose: LINK_PURPOSE) if persisted?
  end

  def self.from_link(token)
    find_signed(token, purpose: LINK_PURPOSE)
  end

  def failed?
    processing_error.present?
  end

  def text_ready?
    hocr_processed_at.present?
  end

  private

  def enqueue_text_extraction
    OcrDocuments::ExtractHocrDataJob.perform_later(id, true)
  end

  def acceptable_image
    return unless original_image.attached?

    errors.add(:original_image, 'must be 1 MB or smaller') if original_image.blob.byte_size > MAX_BYTE_SIZE
    errors.add(:original_image, 'must be a PNG') unless original_image.content_type == 'image/png'
    validate_png_dimensions
  end

  def validate_png_dimensions
    io = pending_upload_io
    return if io.nil?

    width, height = PngDimensions.read(io)
    if width.nil?
      errors.add(:original_image, 'is not a valid PNG file')
    elsif width.zero? || height.zero? || width > MAX_SIDE || height > MAX_SIDE || width * height > MAX_PIXELS
      errors.add(:original_image, "must be at most #{MAX_SIDE} × #{MAX_SIDE} pixels")
    end
  end

  # The file being attached in this save, before it reaches storage.
  def pending_upload_io
    attachable = attachment_changes['original_image']&.attachable
    attachable = attachable[:io] if attachable.is_a?(Hash)
    attachable if attachable.respond_to?(:read) && attachable.respond_to?(:rewind)
  end
end
