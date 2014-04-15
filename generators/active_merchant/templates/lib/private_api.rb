module Killbill #:nodoc:
  module <%= class_name %> #:nodoc:
    class PrivatePaymentPlugin < ActiveRecord::Base
      include Singleton

      private

      def kb_apis
        # The logger should have been configured when the plugin started
        Killbill::<%= class_name %>.kb_apis
      end
    end
  end
end
