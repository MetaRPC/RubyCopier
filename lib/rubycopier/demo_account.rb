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
  end
end
