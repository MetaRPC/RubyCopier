require 'net/http'
require 'json'
require 'uri'
require 'ostruct'

module RubyCopier
  class DemoAccountClient
    def initialize(endpoint = "https://mt5.mrpc.pro")
      clean = endpoint.sub(%r{^https?://}, '').sub(/:443$/, '').chomp('/')
      @base_url = "https://#{clean}"
    end

    def open_demo_account(server: "MetaQuotes-Demo", api_key: "TRIAL")
      uri = URI("#{@base_url}/DemoAccount/Open?server=#{URI.encode_www_form_component(server)}")
      req = Net::HTTP::Get.new(uri)
      req['APIKey'] = api_key
      req['User-Agent'] = 'RubyCopier/1.0.0'

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      res = http.request(req)
      raise "DemoAccount/Open failed with HTTP #{res.code}: #{res.body}" unless res.is_a?(Net::HTTPSuccess)

      data = JSON.parse(res.body)
      OpenStruct.new(
        result_code: data['resultCode'] || 0,
        login: data['login'].to_i,
        password: data['password'],
        investor: data['investor'],
        server: data['server'] || server
      )
    end

    def connect_ex(user:, password:, server: "MetaQuotes-Demo", api_key: "TRIAL")
      params = URI.encode_www_form(user: user, password: password, mtClusterName: server)
      uri = URI("#{@base_url}/ConnectEx?#{params}")
      req = Net::HTTP::Get.new(uri)
      req['APIKey'] = api_key
      req['User-Agent'] = 'RubyCopier/1.0.0'

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 120
      res = http.request(req)
      raise "ConnectEx failed with HTTP #{res.code}: #{res.body}" unless res.is_a?(Net::HTTPSuccess)

      data = JSON.parse(res.body)
      OpenStruct.new(
        terminal_instance_guid: data.dig('data', 'terminalInstanceGuid') || '',
        terminal_type: data.dig('data', 'terminalType') || 'MT5'
      )
    end

    def disconnect(terminal_id, api_key: "TRIAL")
      uri = URI("#{@base_url}/Disconnect")
      req = Net::HTTP::Get.new(uri)
      req['APIKey'] = api_key
      req['id'] = terminal_id
      req['User-Agent'] = 'RubyCopier/1.0.0'

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      res = http.request(req)
      raise "Disconnect failed with HTTP #{res.code}: #{res.body}" unless res.is_a?(Net::HTTPSuccess)

      data = JSON.parse(res.body)
      OpenStruct.new(
        unique_identifier: data.dig('data', 'uniqueIdentifier') || '',
        lifetime_seconds: data.dig('data', 'fullLifeTimeSeconds') || 0
      )
    end

    def order_send(terminal_id, symbol: "EURUSD", operation: "TMT5_ORDER_TYPE_BUY", volume: 0.01, api_key: "TRIAL")
      params = URI.encode_www_form(
        id: terminal_id, symbol: symbol, operation: operation, volume: format('%.2f', volume),
        stoploss: 0, takeprofit: 0, comment: 'RubyCopier_Test'
      )
      uri = URI("#{@base_url}/OrderSend?#{params}")
      req = Net::HTTP::Get.new(uri)
      req['APIKey'] = api_key
      req['id'] = terminal_id
      req['User-Agent'] = 'RubyCopier/1.0.0'

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      res = http.request(req)
      raise "OrderSend failed: #{res.body}" unless res.is_a?(Net::HTTPSuccess)

      data = JSON.parse(res.body)
      ticket = data.dig('data', 'order') || data.dig('data', 'ticket') || data['order'] || data['ticket'] || 0
      ticket.to_i
    end

    def opened_orders(terminal_id, api_key: "TRIAL")
      uri = URI("#{@base_url}/OpenedOrders?id=#{terminal_id}")
      req = Net::HTTP::Get.new(uri)
      req['APIKey'] = api_key
      req['id'] = terminal_id
      req['User-Agent'] = 'RubyCopier/1.0.0'

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      res = http.request(req)
      return [] unless res.is_a?(Net::HTTPSuccess)

      data = JSON.parse(res.body)
      if data.is_a?(Array)
        data
      elsif data.is_a?(Hash)
        data.dig('data', 'positionInfos') || data.dig('data', 'positions') || (data['data'].is_a?(Array) ? data['data'] : [])
      else
        []
      end
    end

    def order_close(terminal_id, ticket, api_key: "TRIAL")
      params = URI.encode_www_form(id: terminal_id, ticket: ticket, volume: 0, slippage: 20)
      uri = URI("#{@base_url}/OrderClose?#{params}")
      req = Net::HTTP::Get.new(uri)
      req['APIKey'] = api_key
      req['id'] = terminal_id
      req['User-Agent'] = 'RubyCopier/1.0.0'

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      res = http.request(req)
      res.body
    end
  end

  def self.to_hyphen_guid(guid)
    clean = guid.sub('mt5_live_', '').delete('-')
    if clean.length == 32
      "#{clean[0..7]}-#{clean[8..11]}-#{clean[12..15]}-#{clean[16..19]}-#{clean[20..31]}"
    else
      guid
    end
  end
end
