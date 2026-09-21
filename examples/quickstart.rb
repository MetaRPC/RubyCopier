require_relative '../lib/rubycopier'

puts "=== RubyCopier Quick Start Demo ==="
api_key = "TRIAL"

demo = RubyCopier::DemoAccountClient.new("https://mt5.mrpc.pro")

# 1. Provision Live Demo Account
puts "\n[1] Provisioning live demo account on MetaQuotes-Demo..."
master = demo.open_demo_account(server: "MetaQuotes-Demo", api_key: api_key)
puts "    Master Account Provisioned: ##{master.login} on #{master.server}"

# 2. Connect Terminal via ConnectEx with APIKey: TRIAL
puts "\n[2] Connecting terminal via ConnectEx (APIKey: #{api_key})..."
conn = demo.connect_ex(user: master.login, password: master.password, server: master.server, api_key: api_key)
puts "    Terminal Connected! Instance GUID: #{conn.terminal_instance_guid}"

# 3. Interacting with Copier Service
puts "\n[3] Interacting with Copier Service (user_key: #{api_key})..."
client = RubyCopier::CopierService.new("copy.mrpc.pro:443", user_key: api_key)
copiers = client.list
puts "    Active Copiers count: #{copiers.length}"

# 4. Cleanly Disconnect Terminal Session
puts "\n[4] Disconnecting terminal session #{conn.terminal_instance_guid}..."
disc = demo.disconnect(conn.terminal_instance_guid, api_key: api_key)
puts "    Terminal Cleanly Disconnected: #{disc.unique_identifier} (Lifetime: #{disc.lifetime_seconds}s)"

puts "\n=== RubyCopier Quick Start Completed Successfully ==="
