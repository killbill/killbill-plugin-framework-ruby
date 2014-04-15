module Killbill #:nodoc:
  module <%= class_name %> #:nodoc:
    class PaymentPlugin < ::Killbill::Plugin::ActiveMerchant::PaymentPlugin

      def initialize
        super(Killbill::<%= class_name %>::<%= class_name %>PaymentMethod,
              Killbill::<%= class_name %>::<%= class_name %>Transaction,
              Killbill::<%= class_name %>::<%= class_name %>Response)
      end

      def start_plugin
        # Change this if needed
        gateway = ::ActiveMerchant::Billing::<%= class_name %>Gateway.new

        ::Killbill::Plugin::ActiveMerchant.initialize! gateway,
                                                       :<%= identifier %>,
                                                       @logger,
                                                       @conf_dir + '/<%= identifier %>.yml',
                                                       @kb_apis

        super

        @logger.info 'Killbill::<%= class_name %>::PaymentPlugin started'
      end
    end
  end
end
