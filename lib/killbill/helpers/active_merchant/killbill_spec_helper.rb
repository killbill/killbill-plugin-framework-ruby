module Killbill
  module Plugin
    module ActiveMerchant
      module RSpec
        include ::Killbill::Plugin::PropertiesHelper

        def create_payment_method(payment_method_model=::Killbill::Plugin::ActiveMerchant::ActiveRecord::PaymentMethod, kb_account_id=nil, kb_tenant_id=nil, properties = [], options = {}, set_default = true, plugin = @plugin)
          kb_payment_method_id = SecureRandom.uuid

          if kb_account_id.nil?
            kb_account_id = SecureRandom.uuid

            # Create a new account
            create_kb_account(kb_account_id, plugin.kb_apis.proxied_services[:account_user_api])
          end

          context = plugin.kb_apis.create_context(kb_tenant_id)
          account = plugin.kb_apis.account_user_api.get_account_by_id(kb_account_id, context)

          # The rest is pure Ruby
          context = context.to_ruby(context)

          # Generate a token
          pm_properties = build_pm_properties(account, options, set_default)

          info = Killbill::Plugin::Model::PaymentMethodPlugin.new
          info.properties = pm_properties
          payment_method = plugin.add_payment_method(kb_account_id, kb_payment_method_id, info, true, properties, context)

          pm = payment_method_model.from_kb_payment_method_id(kb_payment_method_id, context.tenant_id)
          pm.should == payment_method
          pm.kb_account_id.should == kb_account_id
          pm.kb_payment_method_id.should == kb_payment_method_id

          pm
        end

        def build_pm_properties(account = nil, overrides = {}, set_defaults = true)
          cc_number = (overrides.delete(:cc_number) || (set_defaults ? '4242424242424242' : nil))
          cc_first_name = (overrides.delete(:cc_first_name) || (set_defaults ? 'John' : nil))
          cc_last_name = (overrides.delete(:cc_last_name) || (set_defaults ? 'Doe' : nil))
          cc_type = (overrides.delete(:cc_type) || (set_defaults ? 'Visa' : nil))
          cc_exp_month = (overrides.delete(:cc_exp_month) || (set_defaults ? 12 : nil))
          cc_exp_year = (overrides.delete(:cc_exp_year) || (set_defaults ? 2020 : nil))
          cc_last_4 = (overrides.delete(:cc_last_4) || (set_defaults ? 4242 : nil))
          address1 = (overrides.delete(:address1) || (set_defaults ? '5, oakriu road' : nil))
          address2 = (overrides.delete(:address2) || (set_defaults ? 'apt. 298' : nil))
          city = (overrides.delete(:city) || (set_defaults ? 'Gdio Foia' : nil))
          state = (overrides.delete(:state) || (set_defaults ? 'FL' : nil))
          zip = (overrides.delete(:zip) || (set_defaults ? 49302 : nil))
          country = (overrides.delete(:country) || (set_defaults ? 'US' : nil))
          cc_verification_value = (overrides.delete(:cc_verification_value) || (set_defaults ? 1234 : nil))

          properties = []
          properties << build_property('ccNumber', cc_number)
          properties << build_property('ccFirstName', cc_first_name)
          properties << build_property('ccLastName', cc_last_name)
          properties << build_property('ccType', cc_type)
          properties << build_property('ccExpirationMonth', cc_exp_month)
          properties << build_property('ccExpirationYear', cc_exp_year)
          properties << build_property('ccLast4', cc_last_4)
          properties << build_property('email', account.nil? ? Time.now.to_i.to_s + '-test@tester.com' : account.email) # Required by e.g. CyberSource
          properties << build_property('address1', address1)
          properties << build_property('address2', address2)
          properties << build_property('city', city)
          properties << build_property('state', state)
          properties << build_property('zip', zip)
          properties << build_property('country', country)
          properties << build_property('ccVerificationValue', cc_verification_value)

          overrides.each do |key, value|
            properties << build_property(key, value)
          end

          properties
        end

        def create_kb_account(kb_account_id, account_api = @account_api)
          external_key = Time.now.to_i.to_s + '-test'
          email = external_key + '@tester.com'

          account = ::Killbill::Plugin::Model::Account.new
          account.id = kb_account_id
          account.external_key = external_key
          account.email = email
          account.name = 'Integration spec'
          account.currency = :USD

          account_api.accounts << account

          return external_key, kb_account_id
        end

        def build_call_context(tenant_id = '00000011-0022-0033-0044-000000000055')
          call_context = ::Killbill::Plugin::Model::CallContext.new
          call_context.tenant_id = tenant_id
          call_context.to_ruby(call_context)
        end

        def build_plugin(model, name, conf_dir = '.')
          plugin = model.new

          svcs = {
              :account_user_api => ::Killbill::Plugin::ActiveMerchant::RSpec::FakeJavaUserAccountApi.new,
              :payment_api => ::Killbill::Plugin::ActiveMerchant::RSpec::FakeJavaPaymentApi.new,
              :tenant_user_api => ::Killbill::Plugin::ActiveMerchant::RSpec::FakeJavaTenantUserApi.new
          }
          plugin.kb_apis = ::Killbill::Plugin::KillbillApi.new(name, svcs)

          plugin.clock = ::Killbill::Plugin::ActiveMerchant::RSpec::FakeOSGIKillbillClock.new

          plugin.logger = ::Logger.new(STDOUT)
          plugin.logger.level = ::Logger::INFO
          plugin.conf_dir = File.expand_path(conf_dir)
          plugin.root = "/foo/killbill-#{name}/0.0.1"

          plugin
        end

        class FakeJavaUserAccountApi
          attr_accessor :accounts

          def initialize
            @accounts = []
          end

          def get_account_by_id(id, context)
            @accounts.find { |account| account.id == id.to_s }
          end

          def get_account_by_key(external_key, context)
            @accounts.find { |account| account.external_key == external_key.to_s }
          end
        end

        class FakeJavaPaymentApi
          attr_accessor :payments

          def initialize
            @payments = []
          end

          # For testing
          def add_payment(kb_payment_id=SecureRandom.uuid, kb_payment_transaction_id=SecureRandom.uuid, kb_payment_transaction_external_key=SecureRandom.uuid, transaction_type=:PURCHASE)
            kb_payment = get_payment kb_payment_id
            if kb_payment.nil?
              kb_payment = ::Killbill::Plugin::Model::Payment.new
              kb_payment.id = kb_payment_id
              kb_payment.transactions = []
              @payments << kb_payment
            end

            kb_payment_transaction = ::Killbill::Plugin::Model::PaymentTransaction.new
            kb_payment_transaction.id = kb_payment_transaction_id
            kb_payment_transaction.transaction_type = transaction_type
            kb_payment_transaction.external_key = kb_payment_transaction_external_key
            kb_payment_transaction.created_date = Java::org.joda.time.DateTime.new(Java::org.joda.time.DateTimeZone::UTC)
            kb_payment.transactions << kb_payment_transaction

            kb_payment
          end

          def get_payment(id, with_plugin_info=false, with_attempts=false, properties=[], context=nil)
            @payments.find { |payment| payment.id == id.to_s }
          end
        end

        class FakeJavaTenantUserApi

          attr_accessor :per_tenant_config

          def initialize(per_tenant_config = {})
            @per_tenant_config = per_tenant_config
          end

          def get_tenant_values_for_key(key, context)
            result = @per_tenant_config[context.tenant_id.to_s]
            if result
              return [result]
            end
            nil
          end
        end

        class FakeOSGIKillbillClock

          attr_accessor :clock

          def initialize(clock = FakeClock.new)
            @clock = clock
          end

          def get_clock
            @clock
          end
        end

        class FakeClock

          def get_utc_now
            Time.now.utc
          end

          def get_utc_today
            get_utc_now.strftime('%F')
          end
        end
      end
    end
  end
end
