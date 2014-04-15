module Killbill #:nodoc:
  module <%= class_name %> #:nodoc:
    class <%= class_name %>Transaction < Killbill::Plugin::ActiveMerchant::ActiveRecord::Transaction

      self.table_name = '<%= identifier %>_transactions'

    end
  end
end
