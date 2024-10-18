require 'test/unit'
require 'zstd-ruby'
require 'tempfile'
require 'json'
require 'logger'

require_relative '../lib/fluent/plugin/s3_compressor_zstd'

class ZstdCompressorTest < Test::Unit::TestCase
  def test_compress_and_decompress
    # Prepare test data
    data = {"message" => "test log data"}
    json_data = JSON.generate(data) + "\n"

    # Create a temporary file
    tmp = Tempfile.new('zstd-test')
    tmp.binmode

    begin
      # Create a Logger instance
      test_logger = Logger.new(nil)

      # Create a ZstdCompressor instance
      compressor = Fluent::Plugin::S3Output::ZstdCompressor.new(log: test_logger)

      # Mocking chunk
      chunk = Object.new
      def chunk.open(&block)
        io = StringIO.new(JSON.generate({"message" => "test log data"}) + "\n")
        block.call(io)
      end

      # Perform compression
      compressor.compress(chunk, tmp)
      tmp.rewind

      # Read the compressed data
      compressed_data = tmp.read

      # Decompress the data
      decompressed_data = Zstd.decompress(compressed_data)

      # Compare with the original data
      assert_equal(json_data, decompressed_data)
    ensure
      tmp.close
      tmp.unlink
    end
  end
end
