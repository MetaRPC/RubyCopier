require 'securerandom'
require 'ostruct'

module RubyCopier
  class CopierService
    def initialize(endpoint, user_key:, manager_key: nil)
      @endpoint = endpoint
      @user_key = user_key
      @manager_key = manager_key || user_key
    end

    def start(params)
      OpenStruct.new(ok: true, copier_id: SecureRandom.uuid)
    end

    def list
      [
        OpenStruct.new(
          id: SecureRandom.uuid,
          master_type: 'MT5',
          master_user: 10001,
          master_server: 'MetaQuotes-Demo',
          slave_type: 'MT5',
          slave_user: 10002,
          slave_server: 'MetaQuotes-Demo',
          risk_type: 'LotMultiplier',
          risk_value: '1.5',
          paused: false
        )
      ]
    end

    def pause(copier_id, paused: true)
      OpenStruct.new(ok: true)
    end

    def remove(copier_id)
      OpenStruct.new(ok: true)
    end
  end
end
