require 'killbill/plugin'

module Killbill
  module Plugin
    class Payment < PluginBase

      class OperationUnsupportedByGatewayError < NotImplementedError
      end

      def process_payment(kb_account_id, kb_payment_id, kb_payment_method_id, amount_in_cents, currency, options = {})
        raise OperationUnsupportedByGatewayError
      end

      def get_payment_info(kb_account_id, kb_payment_id, options = {})
        raise OperationUnsupportedByGatewayError
      end

      def process_refund(kb_account_id, kb_payment_id, amount_in_cents, currency, options = {})
        raise OperationUnsupportedByGatewayError
      end

      def get_refund_info(kb_account_id, kb_payment_id, options = {})
        raise OperationUnsupportedByGatewayError
      end

      def add_payment_method(kb_account_id, kb_payment_method_id, payment_method_props, set_default, options = {})
        raise OperationUnsupportedByGatewayError
      end

      def delete_payment_method(kb_account_id, kb_payment_method_id, options = {})
        raise OperationUnsupportedByGatewayError
      end

      def get_payment_method_detail(kb_account_id, kb_payment_method_id, options = {})
        raise OperationUnsupportedByGatewayError
      end

      def set_default_payment_method(kb_account_id, kb_payment_method_id, options = {})
        raise OperationUnsupportedByGatewayError
      end

      def get_payment_methods(kb_account_id, refresh_from_gateway, options = {})
        raise OperationUnsupportedByGatewayError
      end

      def reset_payment_methods(kb_account_id, payment_methods)
        raise OperationUnsupportedByGatewayError
      end
    end
  end
end
