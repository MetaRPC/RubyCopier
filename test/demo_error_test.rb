require 'minitest/autorun'
require_relative '../lib/rubycopier'
class DemoErrorTest < Minitest::Test
 def test_http_200_error_is_not_empty_success
  client=RubyCopier::DemoAccountClient.new
  error=assert_raises(RuntimeError){client.parse_reply('{"error":{"errorCode":"MAX_TERMINALS_PER_POD_REACHED","stackTrace":"private trace"}}')}
  assert_includes error.message,'MAX_TERMINALS_PER_POD_REACHED'
  refute_includes error.message,'private trace'
  assert_equal({'data'=>{'positionInfos'=>[]}},client.parse_reply('{"data":{"positionInfos":[]}}'))
 end
end
