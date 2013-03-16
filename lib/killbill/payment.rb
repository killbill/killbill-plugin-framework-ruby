require 'killbill/plugin'
require 'killbill/response/payment_status'
require 'killbill/response/payment_response'
require 'killbill/response/refund_response'
require 'killbill/response/payment_method_response'
require 'killbill/response/payment_method_response_internal'

module Killbill
  module Plugin
    class Payment < PluginBase

      class OperationUnsupportedByGatewayError < NotImplementedError
      end

      def get_name
        raise OperationUnsupportedByGatewayError
      end

      def charge(kb_payment_id, kb_payment_method_id, amount_in_cents, options = {})
        raise OperationUnsupportedByGatewayError
      end

      def get_payment_info(kb_payment_id, options = {})
        raise OperationUnsupportedByGatewayError
      end

      def refund(kb_payment_id, amount_in_cents, options = {})
        raise OperationUnsupportedByGatewayError
      end

      def add_payment_method(kb_account_id, kb_payment_method_id, payment_method_props, set_default, options = {})
        raise OperationUnsupportedByGatewayError
      end

      def delete_payment_method(kb_payment_method_id, options = {})
        raise OperationUnsupportedByGatewayError
      end

      def get_payment_method_detail(kb_account_id, kb_payment_method_id, options = {})
        raise OperationUnsupportedByGatewayError
      end

      def set_default_payment_method(kb_payment_method_id, options = {})
        raise OperationUnsupportedByGatewayError
      end

      def get_payment_methods(kb_account_id, options = {})
        raise OperationUnsupportedByGatewayError
      end

      def reset_payment_methods(payment_methods)
        raise OperationUnsupportedByGatewayError
      end
    end
  end
end
