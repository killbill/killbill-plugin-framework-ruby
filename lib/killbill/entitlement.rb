require 'killbill/plugin'

module Killbill
  module Plugin
    class EntitlementPluginApi < Notification

      class OperationUnsupportedByGatewayError < NotImplementedError
      end

      def prior_call(entitlement_context, properties)
        raise OperationUnsupportedByGatewayError
      end

      def on_success_call(entitlement_context, properties)
        raise OperationUnsupportedByGatewayError
      end

      def on_failure_call(entitlement_context, properties)
        raise OperationUnsupportedByGatewayError
      end
    end
  end
end
