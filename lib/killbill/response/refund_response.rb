module Killbill
  module Plugin

     class RefundResponse

       attr_reader :amount,
                   :created_date,
                   :effective_date,
                   :status,
                   :gateway_error,
                   :gateway_error_code

      def initialize(amount, created_date, effective_date, status, gateway_error, gateway_error_code)
         @amount = amount
         @created_date = created_date
         @effective_date = effective_date
         @status = status
         @gateway_error = gateway_error
         @gateway_error_code = gateway_error_code
       end
     end
  end
end