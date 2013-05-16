
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Gen

      class RefundInfoPlugin

        attr_reader :amount, :created_date, :effective_date, :status, :gateway_error, :gateway_error_code, :reference_id

        def initialize(amount, created_date, effective_date, status, gateway_error, gateway_error_code, reference_id)
          @amount = amount
          @created_date = created_date
          @effective_date = effective_date
          @status = status
          @gateway_error = gateway_error
          @gateway_error_code = gateway_error_code
          @reference_id = reference_id
        end
      end
    end
  end
end
