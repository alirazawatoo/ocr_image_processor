# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PngDimensions do
  it 'reads width and height from the IHDR chunk' do
    io = StringIO.new(png_bytes(width: 30_000, height: 20_000))

    expect(described_class.read(io)).to eq([30_000, 20_000])
  end

  it 'rewinds the stream for the next reader' do
    io = StringIO.new(png_bytes(width: 4, height: 4))
    described_class.read(io)

    expect(io.pos).to eq(0)
  end

  it 'returns nil for data that is not a PNG' do
    expect(described_class.read(StringIO.new("GIF89a\x01\x00\x01\x00" * 3))).to be_nil
    expect(described_class.read(StringIO.new(''))).to be_nil
  end
end
