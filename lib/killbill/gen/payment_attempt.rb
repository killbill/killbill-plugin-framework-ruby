
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Gen

      class PaymentAttempt

        attr_reader :id, :created_date, :updated_date, :effective_date, :gateway_error_code, :gateway_error_msg, :payment_status

        def initialize(id, created_date, updated_date, effective_date, gateway_error_code, gateway_error_msg, payment_status)
          @id = id
          @created_date = created_date
          @updated_date = updated_date
          @effective_date = effective_date
          @gateway_error_code = gateway_error_code
          @gateway_error_msg = gateway_error_msg
          @payment_status = payment_status
        end
      end
    end
  end
end
