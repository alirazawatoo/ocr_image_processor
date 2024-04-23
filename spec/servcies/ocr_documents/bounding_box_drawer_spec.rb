# frozen_string_literal: true

require 'rails_helper'
require 'RMagick'

RSpec.describe BoundingBoxDrawer do
  let(:image) { Magick::Image.new(100, 100) }
  let(:box_coordinates) { [10, 10, 50, 50] }
  let(:draw) { instance_double(Magick::Draw) }
  subject(:bounding_box_drawer) { described_class.new(image, box_coordinates) }

  before do
    allow(Magick::Draw).to receive(:new).and_return(draw)
    allow(draw).to receive(:stroke=)
    allow(draw).to receive(:stroke_width)
  end

  describe '#call' do
    context 'when calling the service' do
      it 'fills the draw object with opacity 0, draws rectangle, and draws the image' do
        expect(draw).to receive(:fill_opacity).with(0)
        expect(draw).to receive(:rectangle).with(*box_coordinates)
        expect(draw).to receive(:draw).with(image)

        bounding_box_drawer.call
      end
    end
  end

  describe 'private methods' do
    describe '#initialize_draw_object' do
      it 'returns a draw object with proper configuration' do
        expect(draw).to receive(:stroke=).with('red')
        expect(draw).to receive(:stroke_width).with(2)

        bounding_box_drawer.send(:initialize_draw_object)
      end
    end
  end
end
