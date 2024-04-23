# frozen_string_literal: true

require 'zlib'

# Builds small in-memory PNGs, including ones whose header declares huge
# dimensions (the shape of a decompression bomb) without the pixel data.
module PngFixtures
  def png_bytes(width:, height:, idat: Zlib::Deflate.deflate("\x00\xFF".b))
    ihdr = [width, height, 8, 0, 0, 0, 0].pack('NNC5')
    PngDimensions::SIGNATURE + png_chunk('IHDR', ihdr) + png_chunk('IDAT', idat) + png_chunk('IEND', '')
  end

  def png_upload(bytes, filename: 'upload.png', content_type: 'image/png')
    file = Tempfile.new([File.basename(filename, '.*'), File.extname(filename)])
    file.binmode
    file.write(bytes)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, content_type, true, original_filename: filename)
  end

  def sample_receipt_upload
    Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/sample_receipt.png'), 'image/png')
  end

  private

  def png_chunk(type, data)
    [data.bytesize].pack('N') + type.b + data.b + [Zlib.crc32(type + data)].pack('N')
  end
end

RSpec.configure { |config| config.include PngFixtures }
