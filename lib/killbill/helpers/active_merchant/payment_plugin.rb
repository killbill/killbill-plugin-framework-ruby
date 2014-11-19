module Killbill
  module Plugin
    module ActiveMerchant
      require 'active_merchant'
      require 'active_record'
      require 'monetize'
      require 'money'
      require 'offsite_payments'

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
          @logger.progname = "#{@identifier.to_s}-plugin"

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
          pool = ::ActiveRecord::Base.connection_pool
          @logger.debug "after_request: pool.active_connection? = #{pool.active_connection?}, pool.connections.size = #{pool.connections.size}, connections = #{pool.connections.inspect}"
          ::ActiveRecord::Base.connection.close if pool.active_connection? # check-in to pool
        end

        def authorize_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
          gateway_call_proc = Proc.new do |gateway, linked_transaction, payment_source, amount_in_cents, options|
            gateway.authorize(amount_in_cents, payment_source, options)
          end

          dispatch_to_gateways(:authorize, kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context, gateway_call_proc)
        end

        def capture_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
          gateway_call_proc = Proc.new do |gateway, linked_transaction, payment_source, amount_in_cents, options|
            gateway.capture(amount_in_cents, linked_transaction.txn_id, options)
          end

          linked_transaction_proc = Proc.new do |amount_in_cents, options|
            # TODO We use the last transaction at the moment, is it good enough?
            last_authorization = @transaction_model.authorizations_from_kb_payment_id(kb_payment_id, context.tenant_id).last
            raise "Unable to retrieve last authorization for operation=capture, kb_payment_id=#{kb_payment_id}, kb_payment_transaction_id=#{kb_payment_transaction_id}, kb_payment_method_id=#{kb_payment_method_id}" if last_authorization.nil?
            last_authorization
          end

          dispatch_to_gateways(:capture, kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context, gateway_call_proc, linked_transaction_proc)
        end

        def purchase_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
          gateway_call_proc = Proc.new do |gateway, linked_transaction, payment_source, amount_in_cents, options|
            gateway.purchase(amount_in_cents, payment_source, options)
          end

          dispatch_to_gateways(:purchase, kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context, gateway_call_proc)
        end

        def void_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, properties, context)
          gateway_call_proc = Proc.new do |gateway, linked_transaction, payment_source, amount_in_cents, options|
            authorization = linked_transaction.txn_id

            # Go to the gateway - while some gateways implementations are smart and have void support 'auth_reversal' and 'void' (e.g. Litle),
            # others (e.g. CyberSource) implement different methods
            linked_transaction.transaction_type == 'AUTHORIZE' && gateway.respond_to?(:auth_reversal) ? gateway.auth_reversal(linked_transaction.amount_in_cents, authorization, options) : gateway.void(authorization, options)
          end

          linked_transaction_proc = Proc.new do |amount_in_cents, options|
            linked_transaction_type = find_value_from_properties(properties, :linked_transaction_type)
            if linked_transaction_type.nil?
              # Default behavior to search for the last transaction
              # If an authorization is being voided, we're performing an 'auth_reversal', otherwise,
              # we're voiding an unsettled capture or purchase (which often needs to happen within 24 hours).
              last_transaction = @transaction_model.purchases_from_kb_payment_id(kb_payment_id, context.tenant_id).last
              if last_transaction.nil?
                last_transaction = @transaction_model.captures_from_kb_payment_id(kb_payment_id, context.tenant_id).last
                if last_transaction.nil?
                  last_transaction = @transaction_model.authorizations_from_kb_payment_id(kb_payment_id, context.tenant_id).last
                  if last_transaction.nil?
                    raise ArgumentError.new("Kill Bill payment #{kb_payment_id} has no auth, capture or purchase, thus cannot be voided")
                  end
                end
              end
            else
              last_transaction = @transaction_model.send("#{linked_transaction_type.to_s}s_from_kb_payment_id", kb_payment_id, context.tenant_id).last
            end
            last_transaction
          end

          dispatch_to_gateways(:void, kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, nil, nil, properties, context, gateway_call_proc, linked_transaction_proc)
        end

        def credit_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
          gateway_call_proc = Proc.new do |gateway, linked_transaction, payment_source, amount_in_cents, options|
            gateway.credit(amount_in_cents, payment_source, options)
          end

          dispatch_to_gateways(:credit, kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context, gateway_call_proc)
        end

        def refund_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context)
          gateway_call_proc = Proc.new do |gateway, linked_transaction, payment_source, amount_in_cents, options|
            gateway.refund(amount_in_cents, linked_transaction.txn_id, options)
          end

          linked_transaction_proc = Proc.new do |amount_in_cents, options|
            linked_transaction_type = find_value_from_properties(properties, :linked_transaction_type)
            transaction             = @transaction_model.find_candidate_transaction_for_refund(kb_payment_id, context.tenant_id, amount_in_cents, linked_transaction_type)
            raise "Unable to retrieve transaction to refund for operation=refund, kb_payment_id=#{kb_payment_id}, kb_payment_transaction_id=#{kb_payment_transaction_id}, kb_payment_method_id=#{kb_payment_method_id}" if transaction.nil?
            transaction
          end

          dispatch_to_gateways(:refund, kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context, gateway_call_proc, linked_transaction_proc)
        end

        def get_payment_info(kb_account_id, kb_payment_id, properties, context)
          # We assume the payment is immutable in the Gateway and only look at our tables
          @transaction_model.transactions_from_kb_payment_id(kb_payment_id, context.tenant_id).collect do |transaction|
            transaction.send("#{@identifier}_response").to_transaction_info_plugin(transaction)
          end
        end

        def search_payments(search_key, offset = 0, limit = 100, properties, context)
          options = properties_to_hash(properties)
          @response_model.search(search_key, context.tenant_id, offset, limit, :payment)
        end

        def add_payment_method(kb_account_id, kb_payment_method_id, payment_method_props, set_default, properties, context)
          all_properties        = (payment_method_props.nil? || payment_method_props.properties.nil? ? [] : payment_method_props.properties) + properties
          options               = properties_to_hash(properties)
          options[:set_default] ||= set_default
          options[:order_id]    ||= kb_payment_method_id

          # Registering a card or a token
          payment_source        = get_payment_source(nil, all_properties, options, context)

          # Go to the gateway
          payment_processor_account_id = options[:payment_processor_account_id] || :default
          gateway                      = lookup_gateway(payment_processor_account_id)
          gw_response                  = gateway.store(payment_source, options)
          response, transaction        = save_response_and_transaction(gw_response, :add_payment_method, kb_account_id, context.tenant_id, payment_processor_account_id)

          if response.success
            # If we have skipped the call to the gateway, we still need to store the payment method
            if options[:skip_gw]
              cc_or_token = payment_source
            else
              # response.authorization may be a String combination separated by ; - don't split it! Some plugins expect it as-is (they split it themselves)
              cc_or_token = response.authorization
            end

            payment_method = @payment_method_model.from_response(kb_account_id, kb_payment_method_id, context.tenant_id, cc_or_token, gw_response, options, {}, @payment_method_model)
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
          payment_processor_account_id = options[:payment_processor_account_id] || :default
          gateway                      = lookup_gateway(payment_processor_account_id)
          if options[:customer_id]
            gw_response = gateway.unstore(options[:customer_id], pm.token, options)
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
            pm = @payment_method_model.create :kb_account_id        => kb_account_id,
                                              :kb_payment_method_id => payment_method_info_plugin.payment_method_id,
                                              :kb_tenant_id         => context.tenant_id,
                                              :token                => payment_method_info_plugin.external_payment_method_id
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
        def dispatch_to_gateways(operation, kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount, currency, properties, context, gateway_call_proc, linked_transaction_proc=nil)
          kb_transaction        = get_kb_transaction(kb_payment_id, kb_payment_transaction_id, context.tenant_id)
          amount_in_cents       = amount.nil? ? nil : to_cents(amount, currency)

          # Setup options for ActiveMerchant
          options               = properties_to_hash(properties)
          options[:order_id]    ||= kb_transaction.external_key
          options[:currency]    ||= currency.to_s.upcase unless currency.nil?
          options[:description] ||= "Kill Bill #{operation.to_s} for #{kb_payment_transaction_id}"

          # Retrieve the payment method
          payment_source        = get_payment_source(kb_payment_method_id, properties, options, context)

          # Sanity checks
          if [:authorize, :purchase, :credit].include?(operation)
            raise "Unable to retrieve payment source for operation=#{operation}, kb_payment_id=#{kb_payment_id}, kb_payment_transaction_id=#{kb_payment_transaction_id}, kb_payment_method_id=#{kb_payment_method_id}" if payment_source.nil?
          end

          # Retrieve the previous transaction for the same operation and payment id - this is useful to detect dups for example
          last_transaction = @transaction_model.send("#{operation.to_s}s_from_kb_payment_id", kb_payment_id, context.tenant_id).last

          # Retrieve the linked transaction (authorization to capture, purchase to refund, etc.)
          linked_transaction = nil
          unless linked_transaction_proc.nil?
            linked_transaction                     = linked_transaction_proc.call(amount_in_cents, options)
            options[:payment_processor_account_id] ||= linked_transaction.payment_processor_account_id
          end

          # Filter before all gateways call
          before_gateways(kb_transaction, last_transaction, payment_source, amount_in_cents, currency, options)

          # Dispatch to the gateways. In most cases (non split settlements), we only dispatch to a single gateway account
          gw_responses                  = []
          responses                     = []
          transactions                  = []
          payment_processor_account_ids = options[:payment_processor_account_ids].nil? ? [options[:payment_processor_account_id] || :default] : options[:payment_processor_account_ids].split(',')
          payment_processor_account_ids.each do |payment_processor_account_id|
            # Find the gateway
            gateway = lookup_gateway(payment_processor_account_id)

            # Filter before each gateway call
            before_gateway(gateway, kb_transaction, last_transaction, payment_source, amount_in_cents, currency, options)

            # Perform the operation in the gateway
            gw_response           = gateway_call_proc.call(gateway, linked_transaction, payment_source, amount_in_cents, options)
            response, transaction = save_response_and_transaction(gw_response, operation, kb_account_id, context.tenant_id, payment_processor_account_id, kb_payment_id, kb_payment_transaction_id, operation.upcase, amount_in_cents, currency)

            # Filter after each gateway call
            after_gateway(response, transaction, gw_response)

            gw_responses << gw_response
            responses << response
            transactions << transaction
          end

          # Filter after all gateways call
          after_gateways(responses, transactions, gw_responses)

          # Merge data
          merge_transaction_info_plugins(payment_processor_account_ids, responses, transactions)
        end

        def get_kb_transaction(kb_payment_id, kb_payment_transaction_id, kb_tenant_id)
          kb_payment     = @kb_apis.payment_api.get_payment(kb_payment_id, false, [], @kb_apis.create_context(kb_tenant_id))
          kb_transaction = kb_payment.transactions.find { |t| t.id == kb_payment_transaction_id }
          # This should never happen...
          raise ArgumentError.new("Unable to find Kill Bill transaction for id #{kb_payment_transaction_id}") if kb_transaction.nil?
          kb_transaction
        end

        def before_gateways(kb_transaction, last_transaction, payment_source, amount_in_cents, currency, options)
        end

        def after_gateways(response, transaction, gw_response)
        end

        def before_gateway(gateway, kb_transaction, last_transaction, payment_source, amount_in_cents, currency, options)
          # Can be used to implement idempotency for example: lookup the payment in the gateway
          # and pass options[:skip_gw] if the payment has already been through
        end

        def after_gateway(response, transaction, gw_response)
        end

        def to_cents(amount, currency)
          # Use Money to compute the amount in cents, as it depends on the currency (1 cent of BTC is 1 Satoshi, not 0.01 BTC)
          ::Monetize.from_numeric(amount, currency).cents.to_i
        end

        def get_payment_source(kb_payment_method_id, properties, options, context)
          cc_number   = find_value_from_properties(properties, 'ccNumber')
          cc_or_token = find_value_from_properties(properties, 'token') || find_value_from_properties(properties, 'cardId')

          if cc_number.blank? and cc_or_token.blank?
            # Existing token
            cc_or_token = @payment_method_model.from_kb_payment_method_id(kb_payment_method_id, context.tenant_id).token
          elsif !cc_number.blank? and cc_or_token.blank?
            # Real credit card
            cc_or_token = ::ActiveMerchant::Billing::CreditCard.new(
                :number             => cc_number,
                :brand              => find_value_from_properties(properties, 'ccType'),
                :month              => find_value_from_properties(properties, 'ccExpirationMonth'),
                :year               => find_value_from_properties(properties, 'ccExpirationYear'),
                :verification_value => find_value_from_properties(properties, 'ccVerificationValue'),
                :first_name         => find_value_from_properties(properties, 'ccFirstName'),
                :last_name          => find_value_from_properties(properties, 'ccLastName')
            )
          else
            # Use specified token
          end

          options[:billing_address] ||= {
              :email    => find_value_from_properties(properties, 'email'),
              :address1 => find_value_from_properties(properties, 'address1'),
              :address2 => find_value_from_properties(properties, 'address2'),
              :city     => find_value_from_properties(properties, 'city'),
              :zip      => find_value_from_properties(properties, 'zip'),
              :state    => find_value_from_properties(properties, 'state'),
              :country  => find_value_from_properties(properties, 'country')
          }

          # To make various gateway implementations happy...
          options[:billing_address].each { |k, v| options[k] ||= v }

          cc_or_token
        end

        def find_value_from_properties(properties, key)
          return nil if key.nil?
          prop = (properties.find { |kv| kv.key.to_s == key.to_s })
          prop.nil? ? nil : prop.value
        end

        def account_currency(kb_account_id, kb_tenant_id)
          account = @kb_apis.account_user_api.get_account_by_id(kb_account_id, @kb_apis.create_context(kb_tenant_id))
          account.currency
        end

        def save_response_and_transaction(gw_response, api_call, kb_account_id, kb_tenant_id, payment_processor_account_id, kb_payment_id=nil, kb_payment_transaction_id=nil, transaction_type=nil, amount_in_cents=0, currency=nil)
          @logger.warn "Unsuccessful #{api_call}: #{gw_response.message}" unless gw_response.success?

          response, transaction = @response_model.create_response_and_transaction(@identifier, @transaction_model, api_call, kb_account_id, kb_payment_id, kb_payment_transaction_id, transaction_type, payment_processor_account_id, kb_tenant_id, gw_response, amount_in_cents, currency, {}, @response_model)

          @logger.debug "Recorded transaction: #{transaction.inspect}" unless transaction.nil?

          return response, transaction
        end

        def lookup_gateway(payment_processor_account_id=:default)
          gateway = ::Killbill::Plugin::ActiveMerchant.gateways[payment_processor_account_id.to_sym]
          raise "Unable to lookup gateway for payment_processor_account_id #{payment_processor_account_id}, gateways: #{::Killbill::Plugin::ActiveMerchant.gateways}" if gateway.nil?
          gateway
        end

        def config
          ::Killbill::Plugin::ActiveMerchant.config
        end

        def hash_to_properties(options)
          merge_properties([], options)
        end

        def properties_to_hash(properties, options = {})
          merged = {}
          (properties || []).each do |p|
            merged[p.key.to_sym] = p.value
          end
          merged.merge(options)
        end

        def merge_properties(properties, options)
          merged = properties_to_hash(properties, options)

          properties = []
          merged.each do |k, v|
            p       = ::Killbill::Plugin::Model::PluginProperty.new
            p.key   = k
            p.value = v
            properties << p
          end
          properties
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
