# frozen_string_literal: true

class BoundingBoxDrawer < ApplicationService
  def initialize(image, box_coordinates)
    super()

    @image = image
    @box_coordinates = box_coordinates
    @draw = initialize_draw_object
  end

  def call
    @draw.fill_opacity(0)
    @draw.rectangle(*@box_coordinates)
    @draw.draw(@image)
  end

  private

  def initialize_draw_object
    draw = Magick::Draw.new
    draw.stroke = 'red'
    draw.stroke_width(2)
    draw
  end
end
