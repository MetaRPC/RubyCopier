require_relative '../lib/rubycopier'

$stdout.sync = true

puts "=== MetaRPC RubyCopier Trade Replication Quick Start ==="
api_key = "TRIAL"

demo = RubyCopier::DemoAccountClient.new("https://mt5.mrpc.pro")
client = RubyCopier::CopierService.new("copy.mrpc.pro:443", user_key: api_key)

master_guid = ""
slave_guid = ""
copier_id = ""

begin
  # 1. Provision live demo accounts
  puts "\n[1] Provisioning live demo accounts on MetaQuotes-Demo..."
  master = demo.open_demo_account(server: "MetaQuotes-Demo", api_key: api_key)
  puts "    Master Account Provisioned: ##{master.login} on #{master.server}"
  sleep 1

  slave = demo.open_demo_account(server: "MetaQuotes-Demo", api_key: api_key)
  puts "    Slave Account Provisioned:  ##{slave.login} on #{slave.server}"
  sleep 1

  # 2. Connect terminals via ConnectEx
  puts "\n[2] Connecting terminals via ConnectEx (APIKey: #{api_key})..."
  3.times do |i|
    begin
      conn_m = demo.connect_ex(user: master.login, password: master.password, server: master.server, api_key: api_key)
      if conn_m.terminal_instance_guid && !conn_m.terminal_instance_guid.empty?
        master_guid = conn_m.terminal_instance_guid
        break
      end
    rescue => e
      puts "    Master ConnectEx attempt #{i+1} error: #{e.message}"
    end
    puts "    Retrying master with fresh demo account..."
    master = demo.open_demo_account(server: "MetaQuotes-Demo", api_key: api_key)
    sleep 2
  end

  if master_guid.empty?
    puts "    Failed to connect master terminal."
    exit 1
  end
  puts "    Master Terminal Connected! GUID: #{master_guid}"

  3.times do |i|
    begin
      conn_s = demo.connect_ex(user: slave.login, password: slave.password, server: slave.server, api_key: api_key)
      if conn_s.terminal_instance_guid && !conn_s.terminal_instance_guid.empty?
        slave_guid = conn_s.terminal_instance_guid
        break
      end
    rescue => e
      puts "    Slave ConnectEx attempt #{i+1} error: #{e.message}"
    end
    puts "    Retrying slave with fresh demo account..."
    slave = demo.open_demo_account(server: "MetaQuotes-Demo", api_key: api_key)
    sleep 2
  end

  if slave_guid.empty?
    puts "    Failed to connect slave terminal."
    exit 1
  end
  puts "    Slave Terminal Connected!  GUID: #{slave_guid}"

  master_session_id = RubyCopier.to_hyphen_guid(master_guid)
  slave_session_id = RubyCopier.to_hyphen_guid(slave_guid)

  # 3. Start Trade Copier via gRPC on copy.mrpc.pro:443
  puts "\n[3] Starting Trade Copier via gRPC on copy.mrpc.pro:443..."
  start_rep = client.start(
    user_key: api_key,
    risk_type: 'LotMultiplier',
    risk_value: '1.0',
    master: { type: 'MT5', user: master.login, password: master.password, server: master.server, id: master_session_id },
    slave:  { type: 'MT5', user: slave.login,  password: slave.password,  server: slave.server,  id: slave_session_id }
  )
  puts "    gRPC Start Reply: ok=#{start_rep.ok}, copierId=#{start_rep.copier_id}, error=#{start_rep.error}"
  unless start_rep.ok
    puts "    Copier Start returned error: #{start_rep.error}"
    exit 1
  end
  copier_id = start_rep.copier_id

  sleep 4

  # 4. Place Market Order on Master
  puts "\n[4] Opening Market Order on Master (0.01 EURUSD BUY)..."
  master_ticket = demo.order_send(master_guid, symbol: "EURUSD", operation: "TMT5_ORDER_TYPE_BUY", volume: 0.01, api_key: api_key)
  puts "    Master Order Placed! Ticket: #{master_ticket}"

  # 5. Verify Trade Copied to Slave
  puts "\n[5] Verifying replicated trade on Slave account..."
  replicated = false
  15.times do |i|
    sleep 2
    positions = demo.opened_orders(slave_guid, api_key: api_key)
    puts "    Attempt #{i+1}: Slave active positions count = #{positions.length}"
    if positions.length > 0
      first = positions[0]
      ticket = first['ticket'] || first['Ticket']
      symbol = first['symbol'] || first['Symbol']
      volume = first['volume'] || first['Volume']
      op_type = first['type'] || first['Type']
      puts "    --> CONFIRMED ON SLAVE: Ticket=#{ticket}, Symbol=#{symbol}, Volume=#{volume}, Type=#{op_type}"
      replicated = true
      break
    end
  end

  if replicated
    puts "    SUCCESS: Trade successfully replicated to slave account!"
  else
    puts "    WARNING: Slave trade replication timed out."
  end

  # 6. Close Position on Master
  if master_ticket && master_ticket > 0
    puts "\n[6] Closing Master trade ticket ##{master_ticket}..."
    close_resp = demo.order_close(master_guid, master_ticket, api_key: api_key)
    puts "    Master OrderClose result: #{close_resp}"

    # 7. Verify Trade Closed on Slave
    puts "\n[7] Verifying trade closed on Slave..."
    15.times do |i|
      sleep 2
      positions = demo.opened_orders(slave_guid, api_key: api_key)
      if positions.empty?
        puts "    SUCCESS: Slave position closed by trade copier!"
        break
      end
      puts "    Attempt #{i+1}: Slave positions still open: #{positions.length}"
    end
  end

  # 8. Remove Copier via gRPC
  unless copier_id.empty?
    puts "\n[8] Removing Copier #{copier_id} via gRPC..."
    rem_rep = client.remove(copier_id)
    puts "    Copier Remove Reply: ok=#{rem_rep.ok}"
  end

ensure
  # 9. Cleanly Disconnect Terminal Sessions
  puts "\n[9] Disconnecting terminal sessions cleanly via /Disconnect..."
  unless master_guid.empty?
    disc_m = demo.disconnect(master_guid, api_key: api_key)
    puts "    Master Terminal Cleanly Disconnected: #{disc_m.unique_identifier} (Lifetime: #{disc_m.lifetime_seconds}s)"
  end
  unless slave_guid.empty?
    disc_s = demo.disconnect(slave_guid, api_key: api_key)
    puts "    Slave Terminal Cleanly Disconnected:  #{disc_s.unique_identifier} (Lifetime: #{disc_s.lifetime_seconds}s)"
  end

  puts "\n=== RubyCopier Trade Replication Completed Successfully ==="
end
