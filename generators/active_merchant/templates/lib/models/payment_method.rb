module Killbill #:nodoc:
  module <%= class_name %> #:nodoc:
    class <%= class_name %>PaymentMethod < ::Killbill::Plugin::ActiveMerchant::ActiveRecord::PaymentMethod

      self.table_name = '<%= identifier %>_payment_methods'

      def self.from_response(kb_account_id, kb_payment_method_id, cc_or_token, response, options, extra_params = {})
        super(kb_account_id,
              kb_payment_method_id,
              cc_or_token,
              response,
              options,
              {
                  # Pass custom key/values here
                  #:params_id => extract(response, 'id'),
                  #:params_card_id => extract(response, 'card', 'id')
              }.merge!(extra_params),
              ::Killbill::<%= class_name %>::<%= class_name %>PaymentMethod)
      end

      def external_payment_method_id
        token
      end
    end
  end
end
