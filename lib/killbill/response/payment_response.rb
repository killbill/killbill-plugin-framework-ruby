module Killbill
  module Plugin
     class PaymentResponse

       attr_reader :amount_in_cents,
                   :created_date,
                   :effective_date,
                   :status,
                   :gateway_error,
                   :gateway_error_code,
                   :first_payment_reference_id,
                   :second_payment_reference_id

      def initialize(amount_in_cents, created_date, effective_date, status, gateway_error=nil, gateway_error_code=nil, first_payment_reference_id=nil, second_payment_reference_id=nil)
         @amount_in_cents = amount_in_cents
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