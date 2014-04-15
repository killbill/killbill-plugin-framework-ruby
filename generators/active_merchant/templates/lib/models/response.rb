module Killbill #:nodoc:
  module <%= class_name %> #:nodoc:
    class <%= class_name %>Response < Killbill::Plugin::ActiveMerchant::ActiveRecord::Response

      self.table_name = '<%= identifier %>_responses'

    end
  end
end
