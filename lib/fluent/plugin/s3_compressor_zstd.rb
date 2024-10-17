# lib/fluent/plugin/s3_compressor_zstd.rb
require 'zstd-ruby' # zstd 압축을 위한 Ruby 라이브러리

module Fluent::Plugin
  class S3Output
    class ZstdCompressor < Compressor
      S3Output.register_compressor('zstd', self)

      config_param :level, :integer, default: 3, desc: "Compression level for zstd (1-22)"

      def ext
        'zst'.freeze
      end

      def content_type
        'application/zstd'.freeze
      end

      def compress(chunk, tmp)
        compressor = Zstd::Compressor.new(level: @level)
        compressed_data = compressor.compress(chunk.read)
        tmp.write(compressed_data)
      rescue => e
        log.warn "zstd compression failed: #{e.message}"
        raise
      end
    end
  end
end
