module Killbill #:nodoc:
  module Test #:nodoc:
    class TestPaymentMethod < ::Killbill::Plugin::ActiveMerchant::ActiveRecord::PaymentMethod

      self.table_name = 'test_payment_methods'

    end
  end
end
