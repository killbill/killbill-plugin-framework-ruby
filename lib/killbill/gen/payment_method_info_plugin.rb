
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Gen

      class PaymentMethodInfoPlugin

        # TODO STEPH added by hand
        include com.ning.billing.payment.plugin.api.PaymentMethodInfoPlugin

        attr_reader :account_id, :payment_method_id, :is_default, :external_payment_method_id

        def initialize(account_id, payment_method_id, is_default, external_payment_method_id)
          @account_id = account_id
          @payment_method_id = payment_method_id
          @is_default = is_default
          @external_payment_method_id = external_payment_method_id
        end
      end
    end
  end
end
