module Killbill #:nodoc:
  module Test #:nodoc:
    class TestResponse < ::Killbill::Plugin::ActiveMerchant::ActiveRecord::Response

      self.table_name = 'test_responses'

      has_one :test_transaction

      def self.sensitive_fields
        [:email]
      end

    end
  end
end
