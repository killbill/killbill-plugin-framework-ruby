module Killbill
  module Plugin
    module ActiveMerchant
      module RSpec

        def create_payment_method(payment_method_model=::Killbill::Plugin::ActiveMerchant::ActiveRecord::PaymentMethod, kb_account_id=nil, kb_tenant_id=nil, properties = [], options = {})
          kb_payment_method_id = SecureRandom.uuid

          if kb_account_id.nil?
            kb_account_id = SecureRandom.uuid

            # Create a new account
            create_kb_account kb_account_id
          end

          context       = @plugin.kb_apis.create_context(kb_tenant_id)
          account       = @plugin.kb_apis.account_user_api.get_account_by_id(kb_account_id, context)

          # The rest is pure Ruby
          context       = context.to_ruby(context)

          # Generate a token
          pm_properties = build_pm_properties(account, options)

          info            = Killbill::Plugin::Model::PaymentMethodPlugin.new
          info.properties = pm_properties
          payment_method  = @plugin.add_payment_method(kb_account_id, kb_payment_method_id, info, true, properties, context)

          pm = payment_method_model.from_kb_payment_method_id(kb_payment_method_id, context.tenant_id)
          pm.should == payment_method
          pm.kb_account_id.should == kb_account_id
          pm.kb_payment_method_id.should == kb_payment_method_id

          pm
        end

        def build_pm_properties(account = nil, overrides = {})
          cc_number             = (overrides.delete(:cc_number) || '4242424242424242')
          cc_first_name         = (overrides.delete(:cc_first_name) || 'John')
          cc_last_name          = (overrides.delete(:cc_last_name) || 'Doe')
          cc_type               = (overrides.delete(:cc_type) || 'Visa')
          cc_exp_month          = (overrides.delete(:cc_exp_month) || 12)
          cc_exp_year           = (overrides.delete(:cc_exp_year) || 2017)
          cc_last_4             = (overrides.delete(:cc_last_4) || 4242)
          address1              = (overrides.delete(:address1) || '5, oakriu road')
          address2              = (overrides.delete(:address2) || 'apt. 298')
          city                  = (overrides.delete(:city) || 'Gdio Foia')
          state                 = (overrides.delete(:state) || 'FL')
          zip                   = (overrides.delete(:zip) || 49302)
          country               = (overrides.delete(:country) || 'US')
          cc_verification_value = (overrides.delete(:cc_verification_value) || 1234)

          properties = []
          properties << create_pm_kv_info('ccNumber', cc_number)
          properties << create_pm_kv_info('ccFirstName', cc_first_name)
          properties << create_pm_kv_info('ccLastName', cc_last_name)
          properties << create_pm_kv_info('ccType', cc_type)
          properties << create_pm_kv_info('ccExpirationMonth', cc_exp_month)
          properties << create_pm_kv_info('ccExpirationYear', cc_exp_year)
          properties << create_pm_kv_info('ccLast4', cc_last_4)
          properties << create_pm_kv_info('email', account.nil? ? Time.now.to_i.to_s + '-test@tester.com' : account.email) # Required by e.g. CyberSource
          properties << create_pm_kv_info('address1', address1)
          properties << create_pm_kv_info('address2', address2)
          properties << create_pm_kv_info('city', city)
          properties << create_pm_kv_info('state', state)
          properties << create_pm_kv_info('zip', zip)
          properties << create_pm_kv_info('country', country)
          properties << create_pm_kv_info('ccVerificationValue', cc_verification_value)

          overrides.each do |key, value|
            properties << create_pm_kv_info(key, value)
          end

          properties
        end

        def create_kb_account(kb_account_id)
          external_key = Time.now.to_i.to_s + '-test'
          email        = external_key + '@tester.com'

          account              = ::Killbill::Plugin::Model::Account.new
          account.id           = kb_account_id
          account.external_key = external_key
          account.email        = email
          account.name         = 'Integration spec'
          account.currency     = :USD

          @account_api.accounts << account

          return external_key, kb_account_id
        end

        def create_pm_kv_info(key, value)
          prop       = ::Killbill::Plugin::Model::PluginProperty.new
          prop.key   = key
          prop.value = value
          prop
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
              kb_payment              = ::Killbill::Plugin::Model::Payment.new
              kb_payment.id           = kb_payment_id
              kb_payment.transactions = []
              @payments << kb_payment
            end

            kb_payment_transaction                  = ::Killbill::Plugin::Model::PaymentTransaction.new
            kb_payment_transaction.id               = kb_payment_transaction_id
            kb_payment_transaction.transaction_type = transaction_type
            kb_payment_transaction.external_key     = kb_payment_transaction_external_key
            kb_payment_transaction.created_date     = Java::org.joda.time.DateTime.new(Java::org.joda.time.DateTimeZone::UTC)
            kb_payment.transactions << kb_payment_transaction

            kb_payment
          end

          def get_payment(id, with_plugin_info=false, properties=[], context=nil)
            @payments.find { |payment| payment.id == id.to_s }
          end
        end
      end
    end
  end
end
