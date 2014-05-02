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
          ::ActiveRecord::Base.connection.close
        end

        def authorize_payment(kb_account_id, kb_payment_id, kb_payment_method_id, amount, currency, properties, context)
          options = properties_to_hash(properties)

          # Use Money to compute the amount in cents, as it depends on the currency (1 cent of BTC is 1 Satoshi, not 0.01 BTC)
          amount_in_cents = Monetize.from_numeric(amount, currency).cents.to_i

          # If the authorization was already made, just return the status (one auth per kb payment id)
          transaction = @transaction_model.authorization_from_kb_payment_id(kb_payment_id, context.tenant_id) rescue nil
          return transaction.send("#{@identifier}_response").to_payment_response(transaction) unless transaction.nil?

          options[:order_id]    ||= kb_payment_id
          options[:currency]    ||= currency.to_s.upcase
          options[:description] ||= "Kill Bill authorization for #{kb_payment_id}"

          # Retrieve the payment method
          if options[:credit_card].blank?
            pm             = @payment_method_model.from_kb_payment_method_id(kb_payment_method_id, context.tenant_id)
            payment_source = pm.token
          else
            payment_source = ::ActiveMerchant::Billing::CreditCard.new(options[:credit_card])
          end

          # Go to the gateway
          gw_response           = gateway.authorize amount_in_cents, payment_source, options
          response, transaction = save_response_and_transaction gw_response, :authorize, kb_account_id, context.tenant_id, kb_payment_id, amount_in_cents, currency

          response.to_payment_response(transaction)
        end

        def capture_payment(kb_account_id, kb_payment_id, kb_payment_method_id, amount, currency, properties, context)
          options = properties_to_hash(properties)

          # Use Money to compute the amount in cents, as it depends on the currency (1 cent of BTC is 1 Satoshi, not 0.01 BTC)
          amount_in_cents = Monetize.from_numeric(amount, currency).cents.to_i

          options[:order_id]    ||= kb_payment_id
          options[:currency]    ||= currency.to_s.upcase
          options[:description] ||= "Kill Bill capture for #{kb_payment_id}"

          # Retrieve the authorization
          authorization = @transaction_model.authorization_from_kb_payment_id(kb_payment_id, context.tenant_id).txn_id

          # Go to the gateway
          gw_response           = gateway.capture amount_in_cents, authorization, options
          response, transaction = save_response_and_transaction gw_response, :capture, kb_account_id, context.tenant_id, kb_payment_id, amount_in_cents, currency

          response.to_payment_response(transaction)
        end

        def void_payment(kb_account_id, kb_payment_id, kb_payment_method_id, properties, context)
          options = properties_to_hash(properties)
          options[:description] ||= "Kill Bill void for #{kb_payment_id}"

          # Retrieve the authorization
          authorization = @transaction_model.authorization_from_kb_payment_id(kb_payment_id, context.tenant_id).txn_id

          # Go to the gateway
          gw_response           = gateway.void authorization, options
          response, transaction = save_response_and_transaction gw_response, :void, kb_account_id, context.tenant_id, kb_payment_id

          response.to_payment_response(transaction)
        end

        def process_payment(kb_account_id, kb_payment_id, kb_payment_method_id, amount, currency, properties, context)
          options = properties_to_hash(properties)

          # Use Money to compute the amount in cents, as it depends on the currency (1 cent of BTC is 1 Satoshi, not 0.01 BTC)
          amount_in_cents = Monetize.from_numeric(amount, currency).cents.to_i

          # If the payment was already made, just return the status
          transaction = @transaction_model.charge_from_kb_payment_id(kb_payment_id, context.tenant_id) rescue nil
          return transaction.send("#{@identifier}_response").to_payment_response(transaction) unless transaction.nil?

          options[:order_id]    ||= kb_payment_id
          options[:currency]    ||= currency.to_s.upcase
          options[:description] ||= "Kill Bill payment for #{kb_payment_id}"

          # Retrieve the payment method
          if options[:credit_card].blank?
            pm             = @payment_method_model.from_kb_payment_method_id(kb_payment_method_id, context.tenant_id)
            payment_source = pm.token
          else
            payment_source = ::ActiveMerchant::Billing::CreditCard.new(options[:credit_card])
          end

          # Go to the gateway
          gw_response           = gateway.purchase amount_in_cents, payment_source, options
          response, transaction = save_response_and_transaction gw_response, :charge, kb_account_id, context.tenant_id, kb_payment_id, amount_in_cents, currency

          response.to_payment_response(transaction)
        end

        def process_refund(kb_account_id, kb_payment_id, amount, currency, properties, context)
          options = properties_to_hash(properties)

          # Use Money to compute the amount in cents, as it depends on the currency (1 cent of BTC is 1 Satoshi, not 0.01 BTC)
          amount_in_cents = Monetize.from_numeric(amount, currency).cents.to_i

          transaction           = @transaction_model.find_candidate_transaction_for_refund(kb_payment_id, context.tenant_id, amount_in_cents)

          # Go to the gateway
          gw_response           = gateway.refund amount_in_cents, transaction.txn_id, options
          response, transaction = save_response_and_transaction gw_response, :refund, kb_account_id, context.tenant_id, kb_payment_id, amount_in_cents, currency

          response.to_refund_response(transaction)
        end

        def get_payment_info(kb_account_id, kb_payment_id, properties, context)
          options = properties_to_hash(properties)

          # We assume the payment is immutable in the Gateway and only look at our tables
          transaction = @transaction_model.charge_from_kb_payment_id(kb_payment_id, context.tenant_id)

          transaction.send("#{@identifier}_response").to_payment_response(transaction)
        end

        def get_refund_info(kb_account_id, kb_payment_id, properties, context)
          options = properties_to_hash(properties)

          # We assume the refund is immutable in the Gateway and only look at our tables
          transactions = @transaction_model.refunds_from_kb_payment_id(kb_payment_id, context.tenant_id)

          transactions.map { |t| t.send("#{@identifier}_response").to_refund_response(t) }
        end

        def add_payment_method(kb_account_id, kb_payment_method_id, payment_method_props, set_default, properties, context)
          options = properties_to_hash(properties)
          options[:set_default] ||= set_default

          # Registering a card or a token
          cc_or_token = find_value_from_payment_method_props(payment_method_props, 'token') || find_value_from_payment_method_props(payment_method_props, 'cardId')
          if cc_or_token.blank?
            # Nope - real credit card
            cc_or_token = ::ActiveMerchant::Billing::CreditCard.new(
                :number             => find_value_from_payment_method_props(payment_method_props, 'ccNumber'),
                :brand              => find_value_from_payment_method_props(payment_method_props, 'ccType'),
                :month              => find_value_from_payment_method_props(payment_method_props, 'ccExpirationMonth'),
                :year               => find_value_from_payment_method_props(payment_method_props, 'ccExpirationYear'),
                :verification_value => find_value_from_payment_method_props(payment_method_props, 'ccVerificationValue'),
                :first_name         => find_value_from_payment_method_props(payment_method_props, 'ccFirstName'),
                :last_name          => find_value_from_payment_method_props(payment_method_props, 'ccLastName')
            )
          end

          options[:billing_address] ||= {
              :email    => find_value_from_payment_method_props(payment_method_props, 'email'),
              :address1 => find_value_from_payment_method_props(payment_method_props, 'address1'),
              :address2 => find_value_from_payment_method_props(payment_method_props, 'address2'),
              :city     => find_value_from_payment_method_props(payment_method_props, 'city'),
              :zip      => find_value_from_payment_method_props(payment_method_props, 'zip'),
              :state    => find_value_from_payment_method_props(payment_method_props, 'state'),
              :country  => find_value_from_payment_method_props(payment_method_props, 'country')
          }

          # To make various gateway implementations happy...
          options[:billing_address].each { |k,v| options[k] ||= v }

          options[:order_id]    ||= kb_payment_method_id

          # Go to the gateway
          gw_response           = gateway.store cc_or_token, options
          response, transaction = save_response_and_transaction gw_response, :add_payment_method, kb_account_id, context.tenant_id

          if response.success
            payment_method = @payment_method_model.from_response(kb_account_id, kb_payment_method_id, context.tenant_id, cc_or_token, gw_response, options)
            payment_method.save!
            payment_method
          else
            raise response.message
          end
        end

        def delete_payment_method(kb_account_id, kb_payment_method_id, properties, context)
          options = properties_to_hash(properties)

          pm = @payment_method_model.from_kb_payment_method_id(kb_payment_method_id, context.tenant_id)

          # Delete the card
          if options[:customer_id]
            gw_response = gateway.unstore(options[:customer_id], pm.token, options)
          else
            gw_response = gateway.unstore(pm.token, options)
          end
          response, transaction = save_response_and_transaction gw_response, :delete_payment_method, kb_account_id, context.tenant_id

          if response.success
            @payment_method_model.mark_as_deleted! kb_payment_method_id, context.tenant_id
          else
            raise response.message
          end
        end

        def get_payment_method_detail(kb_account_id, kb_payment_method_id, properties, context)
          options = properties_to_hash(properties)
          @payment_method_model.from_kb_payment_method_id(kb_payment_method_id, context.tenant_id).to_payment_method_response
        end

        def get_payment_methods(kb_account_id, refresh_from_gateway = false, properties, context)
          options = properties_to_hash(properties)
          @payment_method_model.from_kb_account_id(kb_account_id, context.tenant_id).collect { |pm| pm.to_payment_method_info_response }
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

        def search_payments(search_key, offset = 0, limit = 100, properties, context)
          options = properties_to_hash(properties)
          @response_model.search(search_key, context.tenant_id, offset, limit, :payment)
        end

        def search_refunds(search_key, offset = 0, limit = 100, properties, context)
          options = properties_to_hash(properties)
          @response_model.search(search_key, context.tenant_id, offset, limit, :refund)
        end

        def search_payment_methods(search_key, offset = 0, limit = 100, properties, context)
          options = properties_to_hash(properties)
          @payment_method_model.search(search_key, context.tenant_id, offset, limit)
        end

        def build_form_descriptor(kb_account_id, descriptor_fields, properties, context)
          options = properties_to_hash(descriptor_fields)
          order = options.delete(:order_id)
          account = options.delete(:account_id)
          service_options = {
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
          service_class = integration_module.const_get('Helper')
          service = service_class.new(order, account, service_options)

          # Add the specified fields
          options.each do |field, value|
            mapping = service_class.mappings[field]
            next if mapping.nil?
            case mapping
              when Array
                mapping.each{ |field2| service.add_field(field2, value) }
              when Hash
                options2 = value.is_a?(Hash) ? value : {}
                mapping.each{ |key, field2| service.add_field(field2, options2[key]) }
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
          descriptor = ::Killbill::Plugin::Model::HostedPaymentPageFormDescriptor.new
          descriptor.kb_account_id = kb_account_id
          descriptor.form_method = service.form_method || 'POST'
          descriptor.form_url = service.respond_to?(:credential_based_url) ? service.credential_based_url : integration_module.service_url
          descriptor.form_fields = hash_to_properties(form_fields)
          # Any other custom property
          descriptor.properties = hash_to_properties({})

          descriptor
        end

        def process_notification(notification, properties, context, &proc)
          options = properties_to_hash(properties)

          # Retrieve the ActiveMerchant integration
          integration_module = get_active_merchant_module
          service_class = integration_module.const_get('Notification')
          # notification is either a body or a query string
          service = service_class.new(notification, options)

          if service.respond_to? :acknowledge
            service.acknowledge
          end

          gw_notification = ::Killbill::Plugin::Model::GatewayNotification.new
          gw_notification.kb_payment_id = nil
          gw_notification.status = service.status == 'Completed' ? 200 : 400
          gw_notification.headers = {}
          gw_notification.properties = []

          if service.respond_to? :success_response
            gw_notification.entity = service.success_response(properties_to_hash(properties))
          else
            gw_notification.entity = ''
          end

          yield(gw_notification, service) if block_given?

          gw_notification
        end

        # Utilities

        # Deprecated
        def find_value_from_payment_method_props(payment_method_props, key)
          find_value_from_properties(payment_method_props.properties, key)
        end

        def find_value_from_properties(properties, key)
          prop = (properties.find { |kv| kv.key == key })
          prop.nil? ? nil : prop.value
        end

        def account_currency(kb_account_id)
          account = @kb_apis.account_user_api.get_account_by_id(kb_account_id, @kb_apis.create_context)
          account.currency
        end

        def save_response_and_transaction(response, api_call, kb_account_id, kb_tenant_id, kb_payment_id=nil, amount_in_cents=0, currency=nil)
          @logger.warn "Unsuccessful #{api_call}: #{response.message}" unless response.success?

          # Save the response to our logs
          response = @response_model.from_response(api_call, kb_account_id, kb_payment_id, kb_tenant_id, response)
          response.save!

          transaction = nil
          txn_id      = response.txn_id
          if response.success and !kb_payment_id.blank? and !txn_id.blank?
            # Record the transaction
            transaction = response.send("create_#{@identifier}_transaction!",
                                        :kb_account_id   => kb_account_id,
                                        :kb_tenant_id    => kb_tenant_id,
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
          ::ActiveMerchant::Billing::Integrations.const_get(@identifier.to_s.camelize)
        end
      end
    end
  end
end
