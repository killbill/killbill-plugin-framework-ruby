require 'killbill/payment'

module Killbill
  module Plugin
    class PaymentTest < Payment

      class OperationUnsupportedByGatewayError < NotImplementedError
      end

      def get_name
      end

      def charge(kb_payment_id, kb_payment_method_id, amount_in_cents, options = {})
        PaymentResponse.new(amount_in_cents, DateTime.now, DateTime.now, PaymentStatus::SUCCESS, "gateway_error", "gateway_error_code")
      end

      def get_payment_info(kb_payment_id, options = {})
      end

      def refund(kb_payment_id, amount_in_cents, options = {})
      end

      def add_payment_method(kb_account_id, kb_payment_method_id, payment_method_props, set_default, options = {})
      end

      def delete_payment_method(kb_payment_method_id, options = {})
      end

      def get_payment_method_detail(kb_account_id, kb_payment_method_id, options = {})
      end

      def set_default_payment_method(kb_payment_method_id, options = {})
      end

      def get_payment_methods(kb_account_id, options = {})
      end

      def reset_payment_methods(payment_methods)
      end
    end
  end
end
