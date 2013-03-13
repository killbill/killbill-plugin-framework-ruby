module Killbill
  module Plugin

    class PaymentMethodResponseInternal

      attr_reader :kb_account_id,
                  :kb_payment_method_id,
                  :is_default,
                  :external_payment_method_id

      def initialize(kb_account_id, kb_payment_method_id, is_default, external_payment_method_id)
        @kb_account_id = kb_account_id
        @kb_payment_method_id = kb_payment_method_id
        @is_default = is_default
        @external_payment_method_id = external_payment_method_id
      end

    end
  end
end