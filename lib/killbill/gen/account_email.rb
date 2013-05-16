
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Model

      class AccountEmail

        include com.ning.billing.account.api.AccountEmail

        attr_reader :id, :created_date, :updated_date, :account_id, :email

        def initialize(id, created_date, updated_date, account_id, email)
          @id = id
          @created_date = created_date
          @updated_date = updated_date
          @account_id = account_id
          @email = email
        end
      end
    end
  end
end
