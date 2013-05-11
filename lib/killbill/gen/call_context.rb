
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Gen

      class CallContext #< TenantContext

        attr_reader :user_token, :user_name, :call_origin, :user_type, :reason_code, :comments, :created_date, :updated_date

        # TODO STEPH FIx inheritance to get tenant_id
        def initialize(tenant_id, user_token, user_name, call_origin, user_type, reason_code, comments, created_date, updated_date)
          #super(tenant_id)
          @user_token = user_token
          @user_name = user_name
          @call_origin = call_origin
          @user_type = user_type
          @reason_code = reason_code
          @comments = comments
          @created_date = created_date
          @updated_date = updated_date
        end

      end
    end
  end
end
