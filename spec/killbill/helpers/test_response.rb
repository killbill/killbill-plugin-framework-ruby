module Killbill #:nodoc:
  module Test #:nodoc:
    class TestResponse < ::Killbill::Plugin::ActiveMerchant::ActiveRecord::Response

      self.table_name = 'test_responses'

      has_one :test_transaction

    end
  end
end
