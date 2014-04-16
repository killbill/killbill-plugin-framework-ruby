module Killbill #:nodoc:
  module <%= class_name %> #:nodoc:
    class PrivatePaymentPlugin
      include Singleton

      private

      def kb_apis
        ::Killbill::Plugin::ActiveMerchant.kb_apis
      end

      def gateway
       ::Killbill::Plugin::ActiveMerchant.gateway
      end
    end
  end
end
