
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Gen

      class SubscriptionBundle

        attr_reader :id, :created_date, :updated_date, :blocking_state, :account_id, :external_key, :overdue_state

        def initialize(id, created_date, updated_date, blocking_state, account_id, external_key, overdue_state)
          @id = id
          @created_date = created_date
          @updated_date = updated_date
          @blocking_state = blocking_state
          @account_id = account_id
          @external_key = external_key
          @overdue_state = overdue_state
        end
      end
    end
  end
end
