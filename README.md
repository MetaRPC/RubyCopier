# RubyCopier

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Docs](https://img.shields.io/badge/docs-online-green.svg)](https://github.com/MetaRPC/RubyCopier/tree/main/docs)

Official Ruby SDK for the MetaRPC Trade Copier high-performance trade replication engine via gRPC (`copy.mrpc.pro:443`).

## Installation

```bash
gem install rubycopier
```

## 🏃 How to Run Examples

Clone the repository and run the trade copier example out-of-the-box:

```bash
git clone https://github.com/MetaRPC/RubyCopier.git
cd RubyCopier
bundle install

# 1. Run with default TRIAL key:
bundle exec ruby examples/quickstart.rb

# 2. Or pass your MetaRPC API key directly as an argument:
bundle exec ruby examples/quickstart.rb your_api_key_here

# 3. Or use the MRPC_API_KEY environment variable:
export MRPC_API_KEY="your_api_key_here"        # Windows CMD: set MRPC_API_KEY=your_api_key_here
bundle exec ruby examples/quickstart.rb        # Windows PowerShell: $env:MRPC_API_KEY="your_api_key_here"
```

## Quick Start

See [Quick Start Documentation](https://github.com/MetaRPC/RubyCopier/blob/main/docs/All_Guides/Your_First_Project.md) for a 10-minute walkthrough.
