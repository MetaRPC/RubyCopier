require 'securerandom'
require 'ostruct'
require 'grpc'
require_relative 'copier_services_pb'

module RubyCopier
  class CopierService
    def initialize(endpoint, user_key:, manager_key: nil)
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
        'authorization' => "Bearer #{@user_key}",
        'x-metarpc-client-sdk' => 'RubyCopier/1.0.0'
      }
    end

    def start(params)
      req = Copier::StartRequest.new(
        user_key: params[:user_key] || @user_key,
        manager_key: params[:manager_key] || @manager_key,
        risk_type: params[:risk_type] || 'LotMultiplier',
        risk_value: params[:risk_value] || '1.0'
      )
      begin
        reply = @stub.start(req, metadata: metadata)
        OpenStruct.new(ok: reply.ok, copier_id: reply.copier_id, error: reply.error)
      rescue => e
        OpenStruct.new(ok: false, error: e.message)
      end
    end

    def list
      req = Copier::ListRequest.new(user_key: @user_key)
      begin
        reply = @stub.list(req, metadata: metadata)
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
        []
      end
    end

    def pause(copier_id, paused: true)
      req = Copier::PauseRequest.new(user_key: @user_key, copier_id: copier_id, paused: paused)
      begin
        reply = @stub.pause(req, metadata: metadata)
        OpenStruct.new(ok: reply.ok, error: reply.error)
      rescue => e
        OpenStruct.new(ok: false, error: e.message)
      end
    end

    def remove(copier_id)
      req = Copier::RemoveRequest.new(user_key: @user_key, copier_id: copier_id)
      begin
        reply = @stub.remove(req, metadata: metadata)
        OpenStruct.new(ok: reply.ok, error: reply.error)
      rescue => e
        OpenStruct.new(ok: false, error: e.message)
      end
    end
  end
end
