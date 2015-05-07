module Killbill #:nodoc:
  module Test #:nodoc:
    class TestTransaction < ::Killbill::Plugin::ActiveMerchant::ActiveRecord::Transaction

      self.table_name = 'test_transactions'

      belongs_to :test_response

    end
  end
end
