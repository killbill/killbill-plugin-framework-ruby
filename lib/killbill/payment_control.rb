require 'killbill/plugin'

module Killbill
  module Plugin
    class PaymentControlPluginApi < Notification

      class OperationUnsupportedByGatewayError < NotImplementedError
      end

      def prior_call(control_context, properties)
        raise OperationUnsupportedByGatewayError
      end

      def on_success_call(control_context, properties)
        raise OperationUnsupportedByGatewayError
      end

      def on_failure_call(control_context, properties)
        raise OperationUnsupportedByGatewayError
      end
    end
  end
end
