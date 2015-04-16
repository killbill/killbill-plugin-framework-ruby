module Killbill
  module Plugin
    module ActiveMerchant
      require 'action_controller'
      require 'action_view'
      require 'active_merchant'
      require 'active_support'
      require 'cgi'
      require 'offsite_payments'

      class PrivatePaymentPlugin < ::Killbill::Plugin::Payment

        # Implicit dependencies for form_tag helpers
        include ::ActiveSupport::Configurable
        include ::ActionController::RequestForgeryProtection
        include ::ActionView::Context
        include ::ActionView::Helpers::FormTagHelper
        include ::OffsitePayments::ActionViewHelper

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
          integration_module = ::OffsitePayments.integration(service.to_s.camelize)
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

        def save_response_and_transaction(gw_response, api_call, kb_account_id, kb_tenant_id, payment_processor_account_id, kb_payment_id=nil, kb_payment_transaction_id=nil, transaction_type=nil, amount_in_cents=0, currency=nil)
          logger.warn "Unsuccessful #{api_call}: #{gw_response.message}" unless gw_response.success?

          response, transaction = @response_model.create_response_and_transaction(@identifier, @transaction_model, api_call, kb_account_id, kb_payment_id, kb_payment_transaction_id, transaction_type, payment_processor_account_id, kb_tenant_id, gw_response, amount_in_cents, currency, {}, @response_model)

          logger.debug { "Recorded transaction: #{transaction.inspect}" } unless transaction.nil?

          return response, transaction
        end

        def kb_apis
          ::Killbill::Plugin::ActiveMerchant.kb_apis
        end

        def gateway(payment_processor_account_id=:default, kb_tenant_id=nil)
          gateway = ::Killbill::Plugin::ActiveMerchant.gateways(kb_tenant_id)[payment_processor_account_id.to_sym]
          raise "Unable to lookup gateway for payment_processor_account_id #{payment_processor_account_id}, kb_tenant_id = #{kb_tenant_id}, gateways: #{::Killbill::Plugin::ActiveMerchant.gateways(kb_tenant_id)}" if gateway.nil?
          gateway
        end

        def logger
          ::Killbill::Plugin::ActiveMerchant.logger
        end

        protected

        def reset_output_buffer
          @output_buffer = ''
        end
      end
    end
  end
end
