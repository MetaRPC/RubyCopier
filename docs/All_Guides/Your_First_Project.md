# Quick Start: Your First Project in 10 Minutes

This step-by-step tutorial walks you through building a complete trade replication application in **Ruby** from scratch using **RubyCopier**.

---

## 1. Overview of Steps

In this guide you will:
1. **Provision two demo MetaTrader accounts** via gRPC (`DemoAccount.OpenDemoAccount`).
2. **Connect to MetaRPC Trade Copier** over HTTP/2 gRPC (`copy.mrpc.pro:443`).
3. **Start an active copier** configured with risk multipliers and SL/TP synchronization.
4. **List all registered copiers** and inspect their state.
5. **Stream real-time trade logs** via WebSocket (`/OnTradeLog?id={copierId}`).
6. **Pause and remove** the copier cleanly.

---

## 2. Complete Runnable Code

```ruby
require 'rubycopier'

# 1. Initialize Copier Client
client = RubyCopier::CopierService.new('copy.mrpc.pro:443', user_key: 'YOUR_USER_KEY')

# 2. Start Copier
reply = client.start(
  master: { type: 'MT5', user: 10001, password: 'password1', server: 'MetaQuotes-Demo' },
  slave:  { type: 'MT5', user: 10002, password: 'password2', server: 'MetaQuotes-Demo' },
  risk_type: 'LotMultiplier',
  risk_value: '1.5',
  copy_sl: true,
  copy_tp: true
)

puts "Copier started: #{reply.copier_id}"

# 3. List copiers
copiers = client.list
copiers.each do |c|
  puts "Copier #{c.id}: #{c.master_user} -> #{c.slave_user} (Paused: #{c.paused})"
end

# 4. Cleanup
client.pause(reply.copier_id, paused: true)
client.remove(reply.copier_id)
puts "Copier successfully removed." 
```

---

## 3. How It Works Under the Hood

```mermaid
sequenceDiagram
    autonumber
    participant App as Your Ruby App
    participant Demo as mt5.mrpc.pro (DemoAccount)
    participant Copier as copy.mrpc.pro (CopierService)
    participant WS as /OnTradeLog (WebSocket)
    participant Master as Master Account
    participant Slave as Slave Account

    App->>Demo: OpenDemoAccount (Master)
    Demo-->>App: Master Login & Password
    App->>Demo: OpenDemoAccount (Slave)
    Demo-->>App: Slave Login & Password
    App->>Copier: Start(master, slave, LotMultiplier: 1.5)
    Copier-->>App: StartReply(ok=true, copier_id="...")
    App->>WS: Connect ws(s)://copy.mrpc.pro/OnTradeLog?id=copier_id
    Master->>Copier: Trade Event (OrderSend)
    Copier->>Slave: Replicated Order (Lot: 1.5x)
    Copier->>WS: TradeLog Frame (Ticket, Action, Profit)
    WS-->>App: OnMessage(TradeLog)
    App->>Copier: Remove(copier_id)
```
