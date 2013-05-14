
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Gen

      class ExtBusEvent

        attr_reader :event_type, :object_type, :object_id, :account_id, :tenant_id, :user_token

        def initialize(event_type, object_type, object_id, account_id, tenant_id, user_token)
          @event_type = event_type
          @object_type = object_type
          @object_id = object_id
          @account_id = account_id
          @tenant_id = tenant_id
          @user_token = user_token
        end
      end
    end
  end
end
