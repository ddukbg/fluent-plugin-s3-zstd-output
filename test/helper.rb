# test/helper.rb
require 'bundler/setup'
require 'test/unit'
require 'fluent/test'
require 'zstd-ruby'

$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))

require 'fluent/plugin/out_s3'
require 'fluent/plugin/s3_compressor_zstd'

class Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end
end