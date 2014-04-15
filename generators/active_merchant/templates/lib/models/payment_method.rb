module Killbill #:nodoc:
  module <%= class_name %> #:nodoc:
    class <%= class_name %>PaymentMethod < Killbill::Plugin::ActiveMerchant::ActiveRecord::PaymentMethod

      self.table_name = '<%= identifier %>_payment_methods'

    end
  end
end
