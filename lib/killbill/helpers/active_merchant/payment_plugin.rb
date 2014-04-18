module Killbill
  module Plugin
    module ActiveMerchant
      require 'active_record'
      require 'money'

      class PaymentPlugin < ::Killbill::Plugin::Payment

        def initialize(gateway_builder, identifier, payment_method_model, transaction_model, response_model)
          super()

          @gateway_builder      = gateway_builder
          @identifier           = identifier
          @payment_method_model = payment_method_model
          @transaction_model    = transaction_model
          @response_model       = response_model
        end

        def start_plugin
          ::Killbill::Plugin::ActiveMerchant.initialize! @gateway_builder,
                                                         @identifier.to_sym,
                                                         @logger,
                                                         "#{@conf_dir}/#{@identifier.to_s}.yml",
                                                         @kb_apis

          super

          @logger.info "#{@identifier} payment plugin started"
        end

        # return DB connections to the Pool if required
        def after_request
          ActiveRecord::Base.connection.close
        end

        def process_payment(kb_account_id, kb_payment_id, kb_payment_method_id, amount, currency, call_context = nil, options = {})
          # Use Money to compute the amount in cents, as it depends on the currency (1 cent of BTC is 1 Satoshi, not 0.01 BTC)
          amount_in_cents = Money.new_with_amount(amount, currency).cents.to_i

          # If the payment was already made, just return the status
          transaction = @transaction_model.from_kb_payment_id(kb_payment_id) rescue nil
          return transaction.send("#{@identifier}_response").to_payment_response(transaction) unless transaction.nil?

          options[:order_id]    ||= kb_payment_id
          options[:currency]    ||= currency.to_s.upcase
          options[:description] ||= "Kill Bill payment for #{kb_payment_id}"

          # Retrieve the payment method
          pm                    = @payment_method_model.from_kb_payment_method_id(kb_payment_method_id)

          # Go to the gateway
          gw_response           = gateway.purchase amount_in_cents, pm.send("#{@identifier}_token"), options
          response, transaction = save_response_and_transaction gw_response, :charge, kb_payment_id, amount_in_cents, currency

          response.to_payment_response(transaction)
        end

        def process_refund(kb_account_id, kb_payment_id, amount, currency, call_context = nil, options = {})
          # Use Money to compute the amount in cents, as it depends on the currency (1 cent of BTC is 1 Satoshi, not 0.01 BTC)
          amount_in_cents = Money.new_with_amount(amount, currency).cents.to_i

          transaction           = @transaction_model.find_candidate_transaction_for_refund(kb_payment_id, amount_in_cents)

          # Go to the gateway
          gw_response           = gateway.refund amount_in_cents, transaction.txn_id, options
          response, transaction = save_response_and_transaction gw_response, :refund, kb_payment_id, amount_in_cents, currency

          response.to_refund_response(transaction)
        end

        def get_payment_info(kb_account_id, kb_payment_id, tenant_context = nil, options = {})
          # We assume the payment is immutable in the Gateway and only look at our tables
          transaction = @transaction_model.from_kb_payment_id(kb_payment_id)

          transaction.send("#{@identifier}_response").to_payment_response(transaction)
        end

        def get_refund_info(kb_account_id, kb_payment_id, tenant_context = nil, options = {})
          # We assume the refund is immutable in the Gateway and only look at our tables
          transactions = @transaction_model.refunds_from_kb_payment_id(kb_payment_id)

          transactions.map { |t| t.send("#{@identifier}_response").to_refund_response(t) }
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
                  should_be_deleted       = pm.save
                  break
                  # Otherwise the same token points to 2 different kb_payment_method_id. This should never happen!
                end
              end
            end

            should_be_deleted
          end

          # The remaining elements in payment_methods are not in our table (this should never happen?!)
          payment_methods.each do |payment_method_info_plugin|
            pm = @payment_method_model.new :kb_account_id        => kb_account_id,
                                           :kb_payment_method_id => payment_method_info_plugin.payment_method_id
            pm.send("#{@identifier}_token=", payment_method_info_plugin.external_payment_method_id)
            pm.save
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

        # Utilities

        def find_value_from_payment_method_props(payment_method_props, key)
          prop = (payment_method_props.properties.find { |kv| kv.key == key })
          prop.nil? ? nil : prop.value
        end

        def account_currency(kb_account_id)
          account = @kb_apis.account_user_api.get_account_by_id(kb_account_id, @kb_apis.create_context)
          account.currency
        end

        def save_response_and_transaction(response, api_call, kb_payment_id=nil, amount_in_cents=0, currency=nil)
          @logger.warn "Unsuccessful #{api_call}: #{response.message}" unless response.success?

          # Save the response to our logs
          response = @response_model.from_response(api_call, kb_payment_id, response)
          response.save!

          transaction = nil
          txn_id      = response.txn_id
          if response.success and !kb_payment_id.blank? and !txn_id.blank?
            # Record the transaction
            transaction = response.send("create_#{@identifier}_transaction!",
                                        :amount_in_cents => amount_in_cents,
                                        :currency        => currency,
                                        :api_call        => api_call,
                                        :kb_payment_id   => kb_payment_id,
                                        :txn_id          => txn_id)

            @logger.debug "Recorded transaction: #{transaction.inspect}"
          end
          return response, transaction
        end

        def gateway
          ::Killbill::Plugin::ActiveMerchant.gateway
        end
      end
    end
  end
end
