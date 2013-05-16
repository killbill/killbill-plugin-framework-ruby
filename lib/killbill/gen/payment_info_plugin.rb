
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Gen

      class PaymentInfoPlugin

        attr_reader :amount, :created_date, :effective_date, :status, :gateway_error, :gateway_error_code, :first_payment_reference_id, :second_payment_reference_id

        def initialize(amount, created_date, effective_date, status, gateway_error, gateway_error_code, first_payment_reference_id, second_payment_reference_id)
          @amount = amount
          @created_date = created_date
          @effective_date = effective_date
          @status = status
          @gateway_error = gateway_error
          @gateway_error_code = gateway_error_code
          @first_payment_reference_id = first_payment_reference_id
          @second_payment_reference_id = second_payment_reference_id
        end
      end
    end
  end
end
