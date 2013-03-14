module Killbill
  module Plugin

     class RefundResponse

       attr_reader :amount_in_cents,
                   :created_date,
                   :effective_date,
                   :status,
                   :gateway_error,
                   :gateway_error_code

      def initialize(amount_in_cents, created_date, effective_date, status, gateway_error, gateway_error_code)
         @amount_in_cents = amount_in_cents
         @created_date = created_date
         @effective_date = effective_date
         @status = status
         @gateway_error = gateway_error
         @gateway_error_code = gateway_error_code
       end
     end
  end
end