module Killbill #:nodoc:
  module <%= class_name %> #:nodoc:
    class <%= class_name %>Transaction < ::Killbill::Plugin::ActiveMerchant::ActiveRecord::Transaction

      self.table_name = '<%= identifier %>_transactions'

      belongs_to :<%= identifier %>_response

    end
  end
end
