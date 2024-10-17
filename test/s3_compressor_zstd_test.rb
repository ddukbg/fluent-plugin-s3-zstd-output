require 'test/unit'
require 'zstd-ruby'
require 'tempfile'
require 'json'
require 'logger'

require_relative '../lib/fluent/plugin/s3_compressor_zstd'

class ZstdCompressorTest < Test::Unit::TestCase
  def test_compress_and_decompress
    # 테스트용 데이터 준비
    data = {"message" => "test log data"}
    json_data = JSON.generate(data) + "\n"

    # 임시 파일 생성
    tmp = Tempfile.new('zstd-test')
    tmp.binmode

    begin
      # Logger 인스턴스 생성
      test_logger = Logger.new(nil)

      # ZstdCompressor 인스턴스 생성
      compressor = Fluent::Plugin::S3Output::ZstdCompressor.new(log: test_logger)

      # 청크 모킹
      chunk = Object.new
      def chunk.open(&block)
        io = StringIO.new(JSON.generate({"message" => "test log data"}) + "\n")
        block.call(io)
      end

      # 압축 실행
      compressor.compress(chunk, tmp)
      tmp.rewind

      # 압축된 데이터 읽기
      compressed_data = tmp.read

      # 압축 해제
      decompressed_data = Zstd.decompress(compressed_data)

      # 원본 데이터와 비교
      assert_equal(json_data, decompressed_data)
    ensure
      tmp.close
      tmp.unlink
    end
  end
end
