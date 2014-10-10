module Killbill #:nodoc:
  module <%= class_name %> #:nodoc:
    class <%= class_name %>Response < ::Killbill::Plugin::ActiveMerchant::ActiveRecord::Response

      self.table_name = '<%= identifier %>_responses'

      has_one :<%= identifier %>_transaction

      def self.from_response(api_call, kb_account_id, kb_payment_id, kb_payment_transaction_id, transaction_type, payment_processor_account_id, kb_tenant_id, response, extra_params = {}, model = ::Killbill::<%= class_name %>::<%= class_name %>Response)
        super(api_call,
              kb_account_id,
              kb_payment_id,
              kb_payment_transaction_id,
              transaction_type,
              payment_processor_account_id,
              kb_tenant_id,
              response,
              {
                  # Pass custom key/values here
                  #:params_id => extract(response, 'id'),
                  #:params_card_id => extract(response, 'card', 'id')
              }.merge!(extra_params),
              model)
      end
    end
  end
end
