
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Gen

      class AuditLog

        attr_reader :change_type, :user_name, :created_date, :reason_code, :user_token, :comment

        def initialize(change_type, user_name, created_date, reason_code, user_token, comment)
          @change_type = change_type
          @user_name = user_name
          @created_date = created_date
          @reason_code = reason_code
          @user_token = user_token
          @comment = comment
        end
      end
    end
  end
end
