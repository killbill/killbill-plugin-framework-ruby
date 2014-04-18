module Killbill #:nodoc:
  module <%= class_name %> #:nodoc:
    class <%= class_name %>PaymentMethod < ::Killbill::Plugin::ActiveMerchant::ActiveRecord::PaymentMethod

      self.table_name = '<%= identifier %>_payment_methods'

      def external_payment_method_id
        <%= identifier %>_token
      end
    end
  end
end
