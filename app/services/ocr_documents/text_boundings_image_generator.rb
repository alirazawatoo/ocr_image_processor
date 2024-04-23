# frozen_string_literal: true

module OcrDocuments
  class TextBoundingsImageGenerator < BaseService
    def call
      return if @ocr_document.blank?

      generate_image
    end

    private

    def save_generated_image(image)
      temp_image_path = 'temp_image_with_boxes.png'
      image.write(temp_image_path)

      @ocr_document.generated_image.attach(io: File.open(temp_image_path), filename: 'generated_image.png')
    end

    def draw_text_extractions_boundings(image)
      return if @ocr_document.text_extractions.blank?

      @ocr_document.text_extractions.each do |text_extraction|
        BoundingBoxDrawer.call(image, text_extraction.values_at(:x_start, :y_start, :x_end, :y_end))
      end
    end

    def generate_image
      new_image = Magick::Image.read(@ocr_document.original_image_path).first.copy
      draw_text_extractions_boundings(new_image)
      save_generated_image(new_image)
    end
  end
end
