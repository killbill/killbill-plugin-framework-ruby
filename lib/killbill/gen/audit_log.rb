
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Gen

      class AuditLog

        attr_reader :id, :created_date, :updated_date, :change_type, :user_name, :reason_code, :user_token, :comment

        def initialize(id, created_date, updated_date, change_type, user_name, reason_code, user_token, comment)
          @id = id
          @created_date = created_date
          @updated_date = updated_date
          @change_type = change_type
          @user_name = user_name
          @reason_code = reason_code
          @user_token = user_token
          @comment = comment
        end
      end
    end
  end
end
