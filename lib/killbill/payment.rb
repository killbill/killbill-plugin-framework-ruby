require 'killbill/plugin'

module Killbill
  module Plugin
    class Payment < PluginBase

      class OperationUnsupportedByGatewayError < NotImplementedError
      end

      def process_payment(kb_account_id, kb_payment_id, kb_payment_method_id, amount, currency, properties, context)
        raise OperationUnsupportedByGatewayError
      end

      def get_payment_info(kb_account_id, kb_payment_id, properties, context)
        raise OperationUnsupportedByGatewayError
      end

      def search_payments(search_key, offset, limit, properties, context)
        raise OperationUnsupportedByGatewayError
      end

      def process_refund(kb_account_id, kb_payment_id, refund_amount, currency, properties, context)
        raise OperationUnsupportedByGatewayError
      end

      def get_refund_info(kb_account_id, kb_payment_id, properties, context)
        raise OperationUnsupportedByGatewayError
      end

      def search_refunds(search_key, offset, limit, properties, context)
        raise OperationUnsupportedByGatewayError
      end

      def add_payment_method(kb_account_id, kb_payment_method_id, payment_method_props, set_default, properties, context)
        raise OperationUnsupportedByGatewayError
      end

      def delete_payment_method(kb_account_id, kb_payment_method_id, properties, context)
        raise OperationUnsupportedByGatewayError
      end

      def get_payment_method_detail(kb_account_id, kb_payment_method_id, properties, context)
        raise OperationUnsupportedByGatewayError
      end

      def set_default_payment_method(kb_account_id, kb_payment_method_id, properties, context)
        raise OperationUnsupportedByGatewayError
      end

      def get_payment_methods(kb_account_id, refresh_from_gateway, properties, context)
        raise OperationUnsupportedByGatewayError
      end

      def search_payment_methods(search_key, offset, limit, properties, context)
        raise OperationUnsupportedByGatewayError
      end

      def reset_payment_methods(kb_account_id, payment_methods, properties, context)
        raise OperationUnsupportedByGatewayError
      end
    end
  end
end
