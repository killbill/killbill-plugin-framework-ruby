module Killbill #:nodoc:
  module <%= class_name %> #:nodoc:
    class PrivatePaymentPlugin < ::Killbill::Plugin::ActiveMerchant::PrivatePaymentPlugin
      def initialize(session = {})
        super(:<%= identifier %>,
              ::Killbill::<%= class_name %>::<%= class_name %>PaymentMethod,
              ::Killbill::<%= class_name %>::<%= class_name %>Transaction,
              ::Killbill::<%= class_name %>::<%= class_name %>Response,
              session)
      end
    end
  end
end
