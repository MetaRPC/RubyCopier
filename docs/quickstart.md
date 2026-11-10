# First request with Ruby

List your own copiers to check connectivity and identity without creating a terminal or placing a trade.

## 1. Install

Requires **Ruby 3.1+ and Bundler**. These instructions build from source; they do not assume a registry release exists.

```bash
git clone https://github.com/MetaRPC/RubyCopier.git
cd RubyCopier
bundle install
```

Java on Windows uses `;` for classpath separators. Run C++ builds in a Visual Studio developer shell. Activate your Python virtual environment before installing.

## 2. Set your owner key

=== "Bash"
    ```bash
    export MRPC_API_KEY='your-owner-key'
    ```
=== "PowerShell"
    ```powershell
    $env:MRPC_API_KEY = 'your-owner-key'
    ```

Use the real owner API key, not a broker password, terminal ID or `TRIAL`. Read [authentication](authentication.md) if access is refused.

## 3. Run

```bash
bundle exec ruby examples/list.rb
```

Source: [`examples/list.rb`](https://github.com/MetaRPC/RubyCopier/blob/main/examples/list.rb).

```ruby
require_relative '../lib/rubycopier'
service = RubyCopier::CopierService.new('copy.mrpc.pro:443', user_key: ENV.fetch('MRPC_API_KEY'))
# list raises on failure; [] means a successful response with no copiers.
service.list.each { |copier| puts "#{copier.id}: paused=#{copier.paused}" }
```

A successful empty list means this owner has no copiers. Treat failed requests as errors, not empty accounts.

## 4. Prepare a demo workflow

Read [the lifecycle guide](lifecycle.md), then [choose sizing](sizing.md). Existing replication examples under `examples/` are advanced integration examples: they may provision accounts and trade. Inspect them and their cleanup before running with disposable demos. List is the default starting point.
