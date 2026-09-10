require_relative '../lib/rubycopier'

puts "=== RubyCopier Quick Start ==="
client = RubyCopier::CopierService.new("copy.mrpc.pro:443", user_key: "YOUR_USER_KEY")
reply = client.start(
  master: { type: "MT5", user: 10001, server: "MetaQuotes-Demo" },
  slave: { type: "MT5", user: 10002, server: "MetaQuotes-Demo" },
  risk_type: "LotMultiplier",
  risk_value: "1.5"
)
puts "Started copier ID: #{reply.copier_id}"
