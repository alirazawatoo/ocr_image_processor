# frozen_string_literal: true

# Outlines every box on the image in a single ImageMagick draw pass.
class BoundingBoxDrawer < ApplicationService
  STROKE_COLOR = '#d9480f'
  STROKE_WIDTH = 2

  # boxes: arrays of [x_start, y_start, x_end, y_end] in image pixels
  def initialize(image, boxes)
    super()
    @image = image
    @boxes = boxes
  end

  def call
    return @image if @boxes.empty?

    draw = Magick::Draw.new
    draw.stroke(STROKE_COLOR)
    draw.stroke_width(STROKE_WIDTH)
    draw.fill_opacity(0)
    @boxes.each { |box| draw.rectangle(*box) }
    draw.draw(@image)
    @image
  end
end
