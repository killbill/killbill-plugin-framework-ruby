module Killbill
  module Plugin
    module ActiveMerchant
      require 'active_record'
      require 'money'

      class PaymentPlugin < ::Killbill::Plugin::Payment

        def initialize(payment_method_model, transaction_model, response_model)
          @payment_method_model = payment_method_model
          @transaction_model = transaction_model
          @response_model = response_model
        end

        # return DB connections to the Pool if required
        def after_request
          ActiveRecord::Base.connection.close
        end

        def get_payment_info(kb_account_id, kb_payment_id, tenant_context = nil, options = {})
          # We assume the payment is immutable in the Gateway and only look at our tables
          transaction = @transaction_model.from_kb_payment_id(kb_payment_id)

          transaction.response.to_payment_response
        end

        def get_refund_info(kb_account_id, kb_payment_id, tenant_context = nil, options = {})
          # We assume the refund is immutable in the Gateway and only look at our tables
          transactions = @transaction_model.refunds_from_kb_payment_id(kb_payment_id)

          transactions.map { |t| t.response.to_refund_response }
        end

        def delete_payment_method(kb_account_id, kb_payment_method_id, call_context = nil, options = {})
          @payment_method_model.mark_as_deleted! kb_payment_method_id
        end

        def get_payment_method_detail(kb_account_id, kb_payment_method_id, tenant_context = nil, options = {})
          @payment_method_model.from_kb_payment_method_id(kb_payment_method_id).to_payment_method_response
        end

        def get_payment_methods(kb_account_id, refresh_from_gateway = false, call_context = nil, options = {})
          @payment_method_model.from_kb_account_id(kb_account_id).collect { |pm| pm.to_payment_method_info_response }
        end

        def reset_payment_methods(kb_account_id, payment_methods)
          return if payment_methods.nil?

          pms = @payment_method_model.from_kb_account_id(kb_account_id)

          payment_methods.delete_if do |payment_method_info_plugin|
            should_be_deleted = false
            pms.each do |pm|
              # Do pm and payment_method_info_plugin represent the same payment method?
              if pm.external_payment_method_id == payment_method_info_plugin.external_payment_method_id
                # Do we already have a kb_payment_method_id?
                if pm.kb_payment_method_id == payment_method_info_plugin.payment_method_id
                  should_be_deleted = true
                  break
                elsif pm.kb_payment_method_id.nil?
                  # We didn't have the kb_payment_method_id - update it
                  pm.kb_payment_method_id = payment_method_info_plugin.payment_method_id
                  should_be_deleted = pm.save
                  break
                  # Otherwise the same token points to 2 different kb_payment_method_id. This should never happen!
                end
              end
            end

            should_be_deleted
          end
        end

        def search_payments(search_key, offset = 0, limit = 100, call_context = nil, options = {})
          @response_model.search(search_key, offset, limit, :payment)
        end

        def search_refunds(search_key, offset = 0, limit = 100, call_context = nil, options = {})
          @response_model.search(search_key, offset, limit, :refund)
        end

        def search_payment_methods(search_key, offset = 0, limit = 100, call_context = nil, options = {})
          @payment_method_model.search(search_key, offset, limit)
        end

        protected

        def find_value_from_payment_method_props(payment_method_props, key)
          prop = (payment_method_props.properties.find { |kv| kv.key == key })
          prop.nil? ? nil : prop.value
        end

        def account_currency(kb_account_id)
          account = @kb_apis.account_user_api.get_account_by_id(kb_account_id, @kb_apis.create_context)
          account.currency
        end
      end
    end
  end
end
