
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Model

      class BlockingState

        include com.ning.billing.junction.api.BlockingState

        attr_reader :id, :created_date, :updated_date, :blocked_id, :state_name, :type, :timestamp, :is_block_change, :is_block_entitlement, :is_block_billing, :description, :service

        def initialize(id, created_date, updated_date, blocked_id, state_name, type, timestamp, is_block_change, is_block_entitlement, is_block_billing, description, service)
          @id = id
          @created_date = created_date
          @updated_date = updated_date
          @blocked_id = blocked_id
          @state_name = state_name
          @type = type
          @timestamp = timestamp
          @is_block_change = is_block_change
          @is_block_entitlement = is_block_entitlement
          @is_block_billing = is_block_billing
          @description = description
          @service = service
        end
      end
    end
  end
end
