# frozen_string_literal: true

module OcrDocuments
  # Draws every recognised word box onto a copy of the upload and attaches it
  # as the document's marked image. Works in memory: nothing is written to disk
  # apart from Active Storage's own temp download.
  class TextBoundingsImageGenerator < BaseService
    def call
      return if @ocr_document.blank?

      @ocr_document.original_image.open do |file|
        # The "png:" prefix pins the decoder so ImageMagick never sniffs another format.
        image = Magick::Image.read("png:#{file.path}").first
        BoundingBoxDrawer.call(image, word_boxes)
        attach_marked_image(image)
      ensure
        image&.destroy!
      end
    end

    private

    def word_boxes
      @ocr_document.text_extractions.pluck(:x_start, :y_start, :x_end, :y_end)
    end

    def attach_marked_image(image)
      image.format = 'PNG'
      @ocr_document.generated_image.attach(
        io: StringIO.new(image.to_blob),
        filename: "marked-#{@ocr_document.original_image.filename.base}.png",
        content_type: 'image/png'
      )
    end
  end
end
