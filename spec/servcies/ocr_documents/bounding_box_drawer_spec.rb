# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BoundingBoxDrawer do
  let(:image) { Magick::Image.new(100, 100) { |info| info.background_color = 'white' } }

  def white?(pixel)
    [pixel.red, pixel.green, pixel.blue].all? { |channel| channel == Magick::QuantumRange }
  end

  it 'outlines each box without filling it' do
    described_class.call(image, [[10, 10, 50, 50], [60, 60, 90, 90]])

    expect(white?(image.pixel_color(10, 30))).to be(false)
    expect(white?(image.pixel_color(60, 75))).to be(false)
    expect(white?(image.pixel_color(30, 30))).to be(true)
    expect(white?(image.pixel_color(5, 5))).to be(true)
  end

  it 'leaves the image untouched when there are no boxes' do
    before = image.export_pixels_to_str

    described_class.call(image, [])

    expect(image.export_pixels_to_str).to eq(before)
  end
end
