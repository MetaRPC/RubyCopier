require 'securerandom'
require 'ostruct'
require 'grpc'
require_relative 'copier_services_pb'

module RubyCopier
  class CopierService
    def initialize(endpoint, user_key:, manager_key: nil)
      unless user_key.is_a?(String) && user_key.match?(/\A[!-~]+\z/) && user_key.upcase != 'TRIAL'
        raise ArgumentError, 'A real owner API key is required (printable ASCII, no whitespace).'
      end
      clean = endpoint.sub(%r{^https?://}, '').sub(%r{^wss?://}, '').sub(%r{/$}, '')
      clean += ':443' unless clean.include?(':')
      @endpoint = clean
      @user_key = user_key
      @manager_key = manager_key || user_key

      creds = GRPC::Core::ChannelCredentials.new
      @stub = Copier::CopierService::Stub.new(@endpoint, creds)
    end

    def metadata
      {
        'apikey' => @user_key,
        'x-metarpc-client-sdk' => 'RubyCopier/1.0.0'
      }
    end

    def start(params)
      master_account = params[:master] ? Copier::Account.new(
        type: params[:master][:type] || 'MT5',
        user: params[:master][:user] || 0,
        password: params[:master][:password] || '',
        server: params[:master][:server] || '',
        name: params[:master][:name] || '',
        id: params[:master][:id] || ''
      ) : nil
      slave_account = params[:slave] ? Copier::Account.new(
        type: params[:slave][:type] || 'MT5',
        user: params[:slave][:user] || 0,
        password: params[:slave][:password] || '',
        server: params[:slave][:server] || '',
        name: params[:slave][:name] || '',
        id: params[:slave][:id] || ''
      ) : nil

      req = Copier::StartRequest.new(
        user_key: params[:user_key] || @user_key,
        manager_key: params[:manager_key] || @manager_key,
        risk_type: params[:risk_type] || 'LotMultiplier',
        risk_value: params[:risk_value] || '1.0',
        master: master_account,
        fixed_master_balance: params[:fixed_master_balance] || '',
        copy_sl: params.fetch(:copy_sl, true),
        copy_tp: params.fetch(:copy_tp, true),
        copy_pending_orders: params.fetch(:copy_pending_orders, false),
        reverse_copy: params.fetch(:reverse_copy, false),
        slave: slave_account
      )
      begin
        reply = @stub.start(req, metadata: metadata, deadline: Time.now + 180)
        OpenStruct.new(ok: reply.ok, copier_id: reply.copier_id, error: reply.error)
      rescue => e
        OpenStruct.new(ok: false, error: e.message)
      end
    end

    def list
      req = Copier::ListRequest.new(user_key: @user_key)
      begin
        reply = @stub.list(req, metadata: metadata, deadline: Time.now + 10)
        raise StandardError, reply.error unless reply.ok
        reply.copiers.map do |c|
          OpenStruct.new(
            id: c.id,
            master_type: c.master_type,
            master_user: c.master_user,
            master_server: c.master_server,
            slave_type: c.slave_type,
            slave_user: c.slave_user,
            slave_server: c.slave_server,
            risk_type: c.risk_type,
            risk_value: c.risk_value,
            paused: c.paused,
            pause_reason: c.pause_reason
          )
        end
      rescue => e
        raise
      end
    end

    def pause(copier_id, paused: true)
      req = Copier::PauseRequest.new(user_key: @user_key, copier_id: copier_id, paused: paused)
      begin
        reply = @stub.pause(req, metadata: metadata, deadline: Time.now + 10)
        OpenStruct.new(ok: reply.ok, error: reply.error)
      rescue => e
        OpenStruct.new(ok: false, error: e.message)
      end
    end

    def remove(copier_id)
      req = Copier::RemoveRequest.new(user_key: @user_key, copier_id: copier_id)
      begin
        reply = @stub.remove(req, metadata: metadata, deadline: Time.now + 10)
        OpenStruct.new(ok: reply.ok, error: reply.error)
      rescue => e
        OpenStruct.new(ok: false, error: e.message)
      end
    end
  end
end
