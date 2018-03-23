module Killbill
  module Plugin
    module ActiveMerchant
      require 'active_merchant'
      require 'active_record'
      require 'monetize'
      require 'money'
      require 'offsite_payments'

      class PaymentPlugin < ::Killbill::Plugin::Payment
        include ::Killbill::Plugin::ActiveMerchant::ActiveRecordHelper
        include ::Killbill::Plugin::PropertiesHelper

        def initialize(gateway_builder, identifier, payment_method_model, transaction_model, response_model)
          super()

          @gateway_builder      = gateway_builder
          @identifier           = identifier
          @payment_method_model = payment_method_model
          @transaction_model    = transaction_model
          @response_model       = response_model
        end

        def start_plugin
          @logger.progname = "#{@identifier.to_s}-plugin"

          @config_key_name = "PLUGIN_CONFIG_#{@plugin_name}".to_sym
          ::Killbill::Plugin::ActiveMerchant.initialize! @gateway_builder,
                                                         @identifier.to_sym,
                                                         @logger,
                                                         @config_key_name,
                                                         "#{@conf_dir}/#{@identifier.to_s}.yml",
                                                         @kb_apis

          super

          @logger.info "#{@identifier} payment plugin started"
        end

        def after_request
          # return DB connections to the Pool if required
          close_connection(@logger)
        end

        def on_event(event)
          if (event.event_type == :TENANT_CONFIG_CHANGE || event.event_type == :TENANT_CONFIG_DELETION) &&
              event.meta_data.to_sym == @config_key_name
            ::Killbill::Plugin::ActiveMerchant.invalidate_tenant_config!(event.tenant_id)
          end
        end

        def authorize_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context, extra_params = {})
          gateway_call_proc = Proc.new do |gateway, linked_transaction, payment_source, amount_in_cents, options|
            gateway.authorize(amount_in_cents, payment_source, options)
          end

          dispatch_to_gateways(:authorize, kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context, gateway_call_proc, nil, extra_params)
        end

        def capture_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context, extra_params = {})
          gateway_call_proc = Proc.new do |gateway, linked_transaction, payment_source, amount_in_cents, options|
            gateway.capture(amount_in_cents, linked_transaction.txn_id, options)
          end

          linked_transaction_proc = Proc.new do |amount_in_cents, options|
            # TODO We use the last transaction at the moment, is it good enough?
            last_authorization = @transaction_model.authorizations_from_kb_payment_id(kb_payment_id, context.tenant_id).last
            raise "Unable to retrieve last authorization for operation=capture, kb_payment_id=#{kb_payment_id}, kb_payment_transaction_id=#{kb_payment_transaction_id}, kb_payment_method_id=#{kb_payment_method_id}" if last_authorization.nil?
            last_authorization
          end

          dispatch_to_gateways(:capture, kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context, gateway_call_proc, linked_transaction_proc, extra_params)
        end

        def purchase_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context, extra_params = {})
          gateway_call_proc = Proc.new do |gateway, linked_transaction, payment_source, amount_in_cents, options|
            gateway.purchase(amount_in_cents, payment_source, options)
          end

          dispatch_to_gateways(:purchase, kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context, gateway_call_proc, nil, extra_params)
        end

        def void_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, properties, context, extra_params = {})
          gateway_call_proc = Proc.new do |gateway, linked_transaction, payment_source, amount_in_cents, options|
            authorization = linked_transaction.txn_id

            # Go to the gateway - while some gateways implementations are smart and have void support 'auth_reversal' and 'void' (e.g. Litle),
            # others (e.g. CyberSource) implement different methods
            if linked_transaction.transaction_type == 'AUTHORIZE' && gateway.respond_to?(:auth_reversal)
              options[:currency] ||= linked_transaction.currency
              gateway.auth_reversal(linked_transaction.amount_in_cents, authorization, options)
            else
              gateway.void(authorization, options)
            end
          end

          linked_transaction_proc = Proc.new do |amount_in_cents, options|
            linked_transaction_type = find_value_from_properties(properties, :linked_transaction_type)
            @transaction_model.find_candidate_transaction_for_void(kb_payment_id, context.tenant_id, linked_transaction_type)
          end

          dispatch_to_gateways(:void, kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, nil, nil, properties, context, gateway_call_proc, linked_transaction_proc, extra_params)
        end

        def credit_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context, extra_params = {})
          gateway_call_proc = Proc.new do |gateway, linked_transaction, payment_source, amount_in_cents, options|
            gateway.credit(amount_in_cents, payment_source, options)
          end

          dispatch_to_gateways(:credit, kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context, gateway_call_proc, nil, extra_params)
        end

        def refund_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context, extra_params = {})
          gateway_call_proc = Proc.new do |gateway, linked_transaction, payment_source, amount_in_cents, options|
            gateway.refund(amount_in_cents, linked_transaction.txn_id, options)
          end

          linked_transaction_proc = Proc.new do |amount_in_cents, options|
            linked_transaction_type = find_value_from_properties(properties, :linked_transaction_type)
            transaction             = @transaction_model.find_candidate_transaction_for_refund(kb_payment_id, context.tenant_id, linked_transaction_type)
            # This should never happen
            raise "Unable to retrieve transaction to refund for operation=refund, kb_payment_id=#{kb_payment_id}, kb_payment_transaction_id=#{kb_payment_transaction_id}, kb_payment_method_id=#{kb_payment_method_id}" if transaction.nil?
            transaction
          end

          dispatch_to_gateways(:refund, kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context, gateway_call_proc, linked_transaction_proc, extra_params)
        end

        def get_payment_info(kb_account_id, kb_payment_id, properties, context)
          # We assume the payment is immutable in the Gateway and only look at our tables
          @response_model.from_kb_payment_id(@transaction_model, kb_payment_id, context.tenant_id).collect do |response|
            response.to_transaction_info_plugin(response.send("#{@identifier}_transaction"))
          end
        end

        def search_payments(search_key, offset = 0, limit = 100, properties, context)
          options = properties_to_hash(properties)
          @response_model.search(search_key, context.tenant_id, offset, limit)
        end

        def add_payment_method(kb_account_id, kb_payment_method_id, payment_method_props, set_default, properties, context)
          all_properties        = (payment_method_props.nil? || payment_method_props.properties.nil? ? [] : payment_method_props.properties) + properties
          options               = properties_to_hash(properties)
          options[:set_default] ||= set_default
          options[:order_id]    ||= kb_payment_method_id

          should_skip_gw = Utils.normalized(options, :skip_gw)

          # Registering a card or a token
          if should_skip_gw
            # If nothing is passed, that's fine -  we probably just want a placeholder row in the plugin
            payment_source = get_payment_source(nil, all_properties, options, context) rescue nil
          else
            payment_source = get_payment_source(nil, all_properties, options, context)
          end

          # Go to the gateway
          payment_processor_account_id = Utils.normalized(options, :payment_processor_account_id) || :default
          gateway                      = lookup_gateway(payment_processor_account_id, context.tenant_id)
          gw_response                  = gateway.store(payment_source, options)
          response, transaction        = save_response_and_transaction(gw_response, :add_payment_method, kb_account_id, context.tenant_id, payment_processor_account_id)

          if response.success
            # If we have skipped the call to the gateway, we still need to store the payment method (either a token or the full credit card)
            if should_skip_gw
              cc_or_token = payment_source
            else
              # response.authorization may be a String combination separated by ; - don't split it! Some plugins expect it as-is (they split it themselves)
              cc_or_token = response.authorization
            end

            attributes = properties_to_hash(all_properties)
            # Note: keep the same keys as in build_am_credit_card below
            extra_params = {
                :cc_first_name => Utils.normalized(attributes, :cc_first_name),
                :cc_last_name => Utils.normalized(attributes, :cc_last_name),
                :cc_type => Utils.normalized(attributes, :cc_type),
                :cc_exp_month => Utils.normalized(attributes, :cc_expiration_month),
                :cc_exp_year => Utils.normalized(attributes, :cc_expiration_year),
                :cc_last_4 => Utils.normalized(attributes, :cc_last_4)
            }
            payment_method = @payment_method_model.from_response(kb_account_id, kb_payment_method_id, context.tenant_id, cc_or_token, gw_response, options, extra_params, @payment_method_model)
            payment_method.save!
            payment_method
          else
            raise response.message
          end
        end

        def delete_payment_method(kb_account_id, kb_payment_method_id, properties, context)
          options = properties_to_hash(properties)

          pm      = @payment_method_model.from_kb_payment_method_id(kb_payment_method_id, context.tenant_id)

          # Delete the card
          payment_processor_account_id = Utils.normalized(options, :payment_processor_account_id) || :default
          gateway                      = lookup_gateway(payment_processor_account_id, context.tenant_id)

          customer_id = Utils.normalized(options, :customer_id)
          if customer_id
            gw_response = gateway.unstore(customer_id, pm.token, options)
          else
            gw_response = gateway.unstore(pm.token, options)
          end
          response, transaction = save_response_and_transaction(gw_response, :delete_payment_method, kb_account_id, context.tenant_id, payment_processor_account_id)

          if response.success
            @payment_method_model.mark_as_deleted! kb_payment_method_id, context.tenant_id
          else
            raise response.message
          end
        end

        def get_payment_method_detail(kb_account_id, kb_payment_method_id, properties, context)
          options = properties_to_hash(properties)
          @payment_method_model.from_kb_payment_method_id(kb_payment_method_id, context.tenant_id).to_payment_method_plugin
        end

        # No default implementation
        #def set_default_payment_method(kb_account_id, kb_payment_method_id, properties, context)
        #end

        def get_payment_methods(kb_account_id, refresh_from_gateway = false, properties, context)
          options = properties_to_hash(properties)
          @payment_method_model.from_kb_account_id(kb_account_id, context.tenant_id).collect { |pm| pm.to_payment_method_info_plugin }
        end

        def search_payment_methods(search_key, offset = 0, limit = 100, properties, context)
          options = properties_to_hash(properties)
          @payment_method_model.search(search_key, context.tenant_id, offset, limit)
        end

        def reset_payment_methods(kb_account_id, payment_methods, properties, context)
          return if payment_methods.nil?

          options = properties_to_hash(properties)

          pms = @payment_method_model.from_kb_account_id(kb_account_id, context.tenant_id)

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
            pm = @payment_method_model.create(:kb_account_id        => kb_account_id,
                                              :kb_payment_method_id => payment_method_info_plugin.payment_method_id,
                                              :kb_tenant_id         => context.tenant_id,
                                              :token                => payment_method_info_plugin.external_payment_method_id,
                                              :created_at           => Time.now.utc,
                                              :updated_at           => Time.now.utc)
          end
        end

        def build_form_descriptor(kb_account_id, descriptor_fields, properties, context)
          options            = properties_to_hash(descriptor_fields)
          order              = options.delete(:order_id)
          account            = options.delete(:account_id)
          service_options    = {
              :amount           => options.delete(:amount),
              :currency         => options.delete(:currency),
              :test             => options.delete(:test),
              :credential2      => options.delete(:credential2),
              :credential3      => options.delete(:credential3),
              :credential4      => options.delete(:credential4),
              :country          => options.delete(:country),
              :account_name     => options.delete(:account_name),
              :transaction_type => options.delete(:transaction_type),
              :authcode         => options.delete(:authcode),
              :notify_url       => options.delete(:notify_url),
              :return_url       => options.delete(:return_url),
              :redirect_param   => options.delete(:redirect_param),
              :forward_url      => options.delete(:forward_url)
          }

          # Retrieve the ActiveMerchant integration
          integration_module = get_active_merchant_module
          service_class      = integration_module.const_get('Helper')
          service            = service_class.new(order, account, service_options)

          # Add the specified fields
          options.each do |field, value|
            mapping = service_class.mappings[field]
            next if mapping.nil?
            case mapping
              when Array
                mapping.each { |field2| service.add_field(field2, value) }
              when Hash
                options2 = value.is_a?(Hash) ? value : {}
                mapping.each { |key, field2| service.add_field(field2, options2[key]) }
              else
                service.add_field(mapping, value)
            end
          end

          form_fields = {}
          service.form_fields.each do |field, value|
            form_fields[field] = value
          end
          service.raw_html_fields.each do |field, value|
            form_fields[field] = value
          end

          # Build the response object
          descriptor               = ::Killbill::Plugin::Model::HostedPaymentPageFormDescriptor.new
          descriptor.kb_account_id = kb_account_id
          descriptor.form_method   = service.form_method || 'POST'
          descriptor.form_url      = service.respond_to?(:credential_based_url) ? service.credential_based_url : integration_module.service_url
          descriptor.form_fields   = hash_to_properties(form_fields)
          # Any other custom property
          descriptor.properties    = hash_to_properties({})

          descriptor
        end

        def process_notification(notification, properties, context, &proc)
          options            = properties_to_hash(properties)

          # Retrieve the ActiveMerchant integration
          integration_module = get_active_merchant_module
          service_class      = integration_module.const_get('Notification')
          # notification is either a body or a query string
          service            = service_class.new(notification, options)

          if service.respond_to? :acknowledge
            service.acknowledge
          end

          gw_notification               = ::Killbill::Plugin::Model::GatewayNotification.new
          gw_notification.kb_payment_id = nil
          gw_notification.status        = service.status == 'Completed' ? 200 : 400
          gw_notification.headers       = {}
          gw_notification.properties    = []

          if service.respond_to? :success_response
            gw_notification.entity = service.success_response(properties_to_hash(properties))
          else
            gw_notification.entity = ''
          end

          yield(gw_notification, service) if block_given?

          gw_notification
        end

        # Utilities

        # TODO Split settlements is partially implemented. Left to be done:
        # * payment_source should probably be retrieved per gateway
        # * amount per gateway should be retrieved from the options
        def dispatch_to_gateways(operation, kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context, gateway_call_proc, linked_transaction_proc=nil, extra_params={})
          kb_transaction        = Utils::LazyEvaluator.new { get_kb_transaction(kb_payment_id, kb_payment_transaction_id, context.tenant_id) }
          amount_in_cents       = amount.nil? ? nil : to_cents(amount, currency)

          # Setup options for ActiveMerchant
          options               = properties_to_hash(properties)
          options[:order_id]    ||= (Utils.normalized(options, :external_key_as_order_id) ? kb_transaction.external_key : kb_payment_transaction_id)
          options[:currency]    ||= currency.to_s.upcase unless currency.nil?
          options[:description] ||= "Kill Bill #{operation.to_s} for #{kb_payment_transaction_id}"

          # Retrieve the payment method
          payment_source        = get_payment_source(kb_payment_method_id, properties, options, context)

          # Sanity checks
          if [:authorize, :purchase, :credit].include?(operation)
            raise "Unable to retrieve payment source for operation=#{operation}, kb_payment_id=#{kb_payment_id}, kb_payment_transaction_id=#{kb_payment_transaction_id}, kb_payment_method_id=#{kb_payment_method_id}" if payment_source.nil?
          end

          # Retrieve the previous transaction for the same operation and payment id - this is useful to detect dups for example
          last_transaction = Utils::LazyEvaluator.new { @transaction_model.send("#{operation.to_s}s_from_kb_payment_id", kb_payment_id, context.tenant_id).last }

          # Retrieve the linked transaction (authorization to capture, purchase to refund, etc.)
          linked_transaction = nil
          unless linked_transaction_proc.nil?
            linked_transaction                     = linked_transaction_proc.call(amount_in_cents, options)
            options[:payment_processor_account_id] ||= linked_transaction.payment_processor_account_id
          end

          # Filter before all gateways call
          before_gateways(kb_transaction, last_transaction, payment_source, amount_in_cents, currency, options, context)

          # Dispatch to the gateways. In most cases (non split settlements), we only dispatch to a single gateway account
          gw_responses                  = []
          responses                     = []
          transactions                  = []

          payment_processor_account_ids = Utils.normalized(options, :payment_processor_account_ids)
          if !payment_processor_account_ids
            payment_processor_account_ids = [Utils.normalized(options, :payment_processor_account_id) || :default]
          else
            payment_processor_account_ids = payment_processor_account_ids.split(',')
          end
          payment_processor_account_ids.each do |payment_processor_account_id|
            # Find the gateway
            gateway = lookup_gateway(payment_processor_account_id, context.tenant_id)

            # Filter before each gateway call
            before_gateway(gateway, kb_transaction, last_transaction, payment_source, amount_in_cents, currency, options, context)

            # Perform the operation in the gateway
            gw_response           = gateway_call_proc.call(gateway, linked_transaction, payment_source, amount_in_cents, options)
            response, transaction = save_response_and_transaction(gw_response, operation, kb_account_id, context.tenant_id, payment_processor_account_id, kb_payment_id, kb_payment_transaction_id, operation.upcase, amount_in_cents, currency, extra_params)

            # Filter after each gateway call
            after_gateway(response, transaction, gw_response, context)

            gw_responses << gw_response
            responses << response
            transactions << transaction
          end

          # Filter after all gateways call
          after_gateways(responses, transactions, gw_responses, context)

          # Merge data
          merge_transaction_info_plugins(payment_processor_account_ids, responses, transactions)
        end

        def get_kb_transaction(kb_payment_id, kb_payment_transaction_id, kb_tenant_id)
          kb_payment     = @kb_apis.payment_api.get_payment(kb_payment_id, false, false, [], @kb_apis.create_context(kb_tenant_id))
          kb_transaction = kb_payment.transactions.find { |t| t.id == kb_payment_transaction_id }
          # This should never happen...
          raise ArgumentError.new("Unable to find Kill Bill transaction for id #{kb_payment_transaction_id}") if kb_transaction.nil?
          kb_transaction
        end

        # Default nil value for context only for backward compatibility (Kill Bill 0.14.0)
        def before_gateways(kb_transaction, last_transaction, payment_source, amount_in_cents, currency, options, context = nil)
        end

        # Default nil value for context only for backward compatibility (Kill Bill 0.14.0)
        def after_gateways(response, transaction, gw_response, context = nil)
        end

        # Default nil value for context only for backward compatibility (Kill Bill 0.14.0)
        def before_gateway(gateway, kb_transaction, last_transaction, payment_source, amount_in_cents, currency, options, context = nil)
          # Can be used to implement idempotency for example: lookup the payment in the gateway
          # and pass options[:skip_gw] if the payment has already been through
        end

        # Default nil value for context only for backward compatibility (Kill Bill 0.14.0)
        def after_gateway(response, transaction, gw_response, context = nil)
        end

        def to_cents(amount, currency)
          # Use Money to compute the amount in cents, as it depends on the currency (1 cent of BTC is 1 Satoshi, not 0.01 BTC)
          ::Monetize.from_numeric(amount, currency).cents.to_i
        end

        def get_payment_source(kb_payment_method_id, properties, options, context)
          attributes = properties_to_hash(properties, options)

          # Use ccNumber for:
          # * the real number
          # * in-house token (e.g. proxy tokenization)
          # * token from a token service provider (e.g. ApplePay)
          # If not specified, the rest of the card details will be retrieved from the locally stored payment method (if available)
          cc_number = Utils.normalized(attributes, :cc_number)
          # Use token for the token stored in an external vault. The token itself should be enough to process payments.
          token = Utils.normalized(attributes, :token) || Utils.normalized(attributes, :card_id) || Utils.normalized(attributes, :payment_data)

          if token.blank?
            pm = nil
            begin
              pm = @payment_method_model.from_kb_payment_method_id(kb_payment_method_id, context.tenant_id)
            rescue => e
              raise e if cc_number.blank?
            end unless kb_payment_method_id.nil?

            if cc_number.blank? && !pm.nil?
              # Lookup existing token
              if pm.token.blank?
                # Real credit card
                cc_or_token = build_am_credit_card(pm.cc_number, attributes, pm)
              else
                # Tokenized card
                cc_or_token = pm.token
              end
            else
              # Real credit card or network tokenization
              cc_or_token = build_am_credit_card(cc_number, attributes, pm)
            end
          else
            # Use specified token
            cc_or_token = build_am_token(token, attributes)
          end

          options[:billing_address] ||= {
              :email => Utils.normalized(attributes, :email),
              :address1 => Utils.normalized(attributes, :address1) || (pm.nil? ? nil : pm.address1),
              :address2 => Utils.normalized(attributes, :address2) || (pm.nil? ? nil : pm.address2),
              :city => Utils.normalized(attributes, :city) || (pm.nil? ? nil : pm.city),
              :zip => Utils.normalized(attributes, :zip) || (pm.nil? ? nil : pm.zip),
              :state => Utils.normalized(attributes, :state) || (pm.nil? ? nil : pm.state),
              :country => Utils.normalized(attributes, :country) || (pm.nil? ? nil : pm.country)
          }

          # To make various gateway implementations happy...
          options[:billing_address].each { |k, v| options[k] ||= v }

          cc_or_token
        end

        def build_am_credit_card(cc_number, attributes, pm=nil)
          card_attributes = {
              :number => cc_number,
              :brand => Utils.normalized(attributes, :cc_type) || (pm.nil? ? nil : pm.cc_type),
              :month => Utils.normalized(attributes, :cc_expiration_month) || (pm.nil? ? nil : pm.cc_exp_month),
              :year => Utils.normalized(attributes, :cc_expiration_year) || (pm.nil? ? nil : pm.cc_exp_year),
              :verification_value => Utils.normalized(attributes, :cc_verification_value) || (pm.nil? ? nil : pm.cc_verification_value),
              :first_name => Utils.normalized(attributes, :cc_first_name) || (pm.nil? ? nil : pm.cc_first_name),
              :last_name => Utils.normalized(attributes, :cc_last_name) || (pm.nil? ? nil : pm.cc_last_name)
          }
          tokenization_attributes = {
              :eci => Utils.normalized(attributes, :eci),
              :payment_cryptogram => Utils.normalized(attributes, :payment_cryptogram),
              :transaction_id => Utils.normalized(attributes, :transaction_id)
          }

          if tokenization_attributes[:eci].nil? &&
              tokenization_attributes[:payment_cryptogram].nil? &&
              tokenization_attributes[:transaction_id].nil?
            ::ActiveMerchant::Billing::CreditCard.new(card_attributes)
          else
            # NetworkTokenizationCreditCard is exactly like a credit card but with EMV/3DS standard payment network tokenization data
            ::ActiveMerchant::Billing::NetworkTokenizationCreditCard.new(card_attributes.merge(tokenization_attributes))
          end
        end

        def build_am_token(token, attributes)
          token_attributes = {
              :payment_instrument_name => Utils.normalized(attributes, :payment_instrument_name),
              :payment_network => Utils.normalized(attributes, :payment_network),
              :transaction_identifier => Utils.normalized(attributes, :transaction_identifier)
          }

          if token_attributes[:payment_instrument_name].nil? &&
              token_attributes[:payment_network].nil? &&
              token_attributes[:transaction_identifier].nil?
            token
          else
            # Use ActiveSupport since ActiveMerchant does the same
            payment_data = ::ActiveSupport::JSON.decode(token) rescue token
            # PaymentToken is meant for modeling proprietary payment token structures (like stripe and apple_pay)
            ::ActiveMerchant::Billing::ApplePayPaymentToken.new(payment_data, token_attributes)
          end
        end

        def account_currency(kb_account_id, kb_tenant_id)
          account = @kb_apis.account_user_api.get_account_by_id(kb_account_id, @kb_apis.create_context(kb_tenant_id))
          account.currency
        end

        def save_response_and_transaction(gw_response, api_call, kb_account_id, kb_tenant_id, payment_processor_account_id, kb_payment_id=nil, kb_payment_transaction_id=nil, transaction_type=nil, amount_in_cents=0, currency=nil, extra_params={})
          @logger.warn "Unsuccessful #{api_call}: #{gw_response.message}" unless gw_response.success?

          response, transaction = @response_model.create_response_and_transaction(@identifier, @transaction_model, api_call, kb_account_id, kb_payment_id, kb_payment_transaction_id, transaction_type, payment_processor_account_id, kb_tenant_id, gw_response, amount_in_cents, currency, extra_params, @response_model)

          @logger.debug { "Recorded transaction: #{transaction.inspect}" } unless transaction.nil?

          return response, transaction
        end

        def lookup_gateway(payment_processor_account_id=:default, kb_tenant_id=nil)
          gateway = ::Killbill::Plugin::ActiveMerchant.gateways(kb_tenant_id)[payment_processor_account_id.to_sym]
          raise "Unable to lookup gateway for payment_processor_account_id #{payment_processor_account_id}, kb_tenant_id = #{kb_tenant_id}, gateways: #{::Killbill::Plugin::ActiveMerchant.gateways(kb_tenant_id)}" if gateway.nil?
          gateway
        end

        def config(kb_tenant_id=nil)
          ::Killbill::Plugin::ActiveMerchant.config(kb_tenant_id)
        end

        def get_active_merchant_module
          ::OffsitePayments.integration(@identifier.to_s.camelize)
        end

        def merge_transaction_info_plugins(payment_processor_account_ids, responses, transactions)
          result                             = Killbill::Plugin::Model::PaymentTransactionInfoPlugin.new
          result.amount                      = nil
          result.properties                  = []
          result.status                      = :PROCESSED
          # Nothing meaningful we can set here
          result.first_payment_reference_id  = nil
          result.second_payment_reference_id = nil

          responses.each_with_index do |response, idx|
            t_info_plugin = response.to_transaction_info_plugin(transactions[idx])
            if responses.size == 1
              # We're done
              return t_info_plugin
            end

            # Unique values
            [:kb_payment_id, :kb_transaction_payment_id, :transaction_type, :currency].each do |element|
              result_element        = result.send(element)
              t_info_plugin_element = t_info_plugin.send(element)
              if result_element.nil?
                result.send("#{element}=", t_info_plugin_element)
              elsif result_element != t_info_plugin_element
                raise "#{element.to_s} mismatch, #{result_element} != #{t_info_plugin_element}"
              end
            end

            # Arbitrary values
            [:created_date, :effective_date].each do |element|
              if result.send(element).nil?
                result.send("#{element}=", t_info_plugin.send(element))
              end
            end

            t_info_plugin.properties.each do |property|
              prop       = Killbill::Plugin::Model::PluginProperty.new
              prop.key   = "#{property.key}_#{payment_processor_account_ids[idx]}"
              prop.value = property.value
              result.properties << prop
            end

            if result.amount.nil?
              result.amount = t_info_plugin.amount
            elsif !t_info_plugin.nil?
              # TODO Adding decimals - are we losing precision?
              result.amount = result.amount + t_info_plugin.amount
            end

            # We set an error status if we have at least one error
            # TODO Does this work well with retries?
            if t_info_plugin.status == :ERROR
              result.status             = :ERROR

              # Return the first error
              result.gateway_error      = t_info_plugin.gateway_error if  result.gateway_error.nil?
              result.gateway_error_code = t_info_plugin.gateway_error_code if  result.gateway_error_code.nil?
            end
          end

          result
        end
      end
    end
  end
end
