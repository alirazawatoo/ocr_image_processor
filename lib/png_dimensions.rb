# frozen_string_literal: true

# Reads width and height from a PNG's IHDR chunk without decoding pixels, so
# oversized images can be rejected before ImageMagick or Tesseract open them.
module PngDimensions
  SIGNATURE = "\x89PNG\r\n\x1A\n".b
  HEADER_BYTES = 24

  # Returns [width, height], or nil when the bytes are not a PNG header.
  def self.read(io)
    header = io.read(HEADER_BYTES)
    io.rewind
    return unless header && header.bytesize == HEADER_BYTES
    return unless header.start_with?(SIGNATURE) && header[12, 4] == 'IHDR'

    header[16, 8].unpack('NN')
  end
end
