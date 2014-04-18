module Killbill
  module Plugin
    module ActiveMerchant
      require 'action_controller'
      require 'action_view'
      require 'active_support'
      require 'cgi'

      class PrivatePaymentPlugin < ::Killbill::Plugin::Payment

        # Implicit dependencies for form_tag helpers
        include ::ActiveSupport::Configurable
        include ::ActionController::RequestForgeryProtection
        include ::ActionView::Context
        include ::ActionView::Helpers::FormTagHelper
        include ::ActiveMerchant::Billing::Integrations::ActionViewHelper

        # For RequestForgeryProtection
        attr_reader :session

        def initialize(identifier, payment_method_model, transaction_model, response_model, session = {})
          @identifier           = identifier
          @payment_method_model = payment_method_model
          @transaction_model    = transaction_model
          @response_model       = response_model

          @session = session
          reset_output_buffer
        end

        # Valid options: :amount, :currency, :test, :credential2, :credential3, :credential4, :country, :account_name,
        #                :transaction_type, :authcode, :notify_url, :return_url, :redirect_param, :forward_url
        #
        # Additionally, you can have a :html key which will be passed through to the link_to helper
        def payment_link_for(name, order_id, account_id, service, options = {})
          integration_module = ::ActiveMerchant::Billing::Integrations.const_get(service.to_s.camelize)
          service_class      = integration_module.const_get('Helper')

          link_options = options.delete(:html) || {}
          service      = service_class.new(order_id, account_id, options)

          service_url = service.respond_to?(:credential_based_url) ? service.credential_based_url : integration_module.service_url

          # Hack for QIWI which requires 'id' to be the first query parameter...
          params      = service.form_fields
          order_key   = service.mappings[:order]
          url         = service_url + '?' + "#{CGI.escape(order_key.to_param)}=#{CGI.escape(params[order_key].to_s)}"
          params.delete order_key
          url += '&' + params.to_query

          # service.form_fields are query parameters
          link_to name, url, link_options.merge(service.form_fields)
        end

        # Valid options: :amount, :currency, :test, :credential2, :credential3, :credential4, :country, :account_name,
        #                :transaction_type, :authcode, :notify_url, :return_url, :redirect_param, :forward_url
        #
        # Additionally, you can have a :html key which will be passed through to the form_tag helper
        def payment_form_for(order_id, account_id, service, options = {}, &proc)
          # For ActiveMerchant routing
          options[:service] = service

          options[:html]                              ||= {}
          options[:html][:disable_authenticity_token] ||= true
          options[:html][:enforce_utf8]               ||= false

          payment_service_for(order_id, account_id, options, &proc)

          output_buffer
        end

        protected

        def reset_output_buffer
          @output_buffer = ''
        end

        def save_response(response, api_call)
          save_response_and_transaction(response, api_call)[0]
        end

        def save_response_and_transaction(response, api_call, kb_payment_id=nil, amount_in_cents=0, currency=nil)
          logger.warn "Unsuccessful #{api_call}: #{response.message}" unless response.success?

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
                                        :stripe_txn_id   => txn_id)

            logger.debug "Recorded transaction: #{transaction.inspect}"
          end
          return response, transaction
        end

        def kb_apis
          ::Killbill::Plugin::ActiveMerchant.kb_apis
        end

        def gateway
          ::Killbill::Plugin::ActiveMerchant.gateway
        end

        def logger
          ::Killbill::Plugin::ActiveMerchant.logger
        end
      end
    end
  end
end