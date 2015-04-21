require 'spec_helper'

describe Killbill::Plugin::ActiveMerchant::PaymentPlugin do
  include Killbill::Plugin::ActiveMerchant::RSpec

  let(:payment_api) { ::Killbill::Plugin::ActiveMerchant::RSpec::FakeJavaPaymentApi.new }
  let(:tenant_api) { ::Killbill::Plugin::ActiveMerchant::RSpec::FakeJavaTenantUserApi.new }
  let(:kb_apis) { ::Killbill::Plugin::KillbillApi.new('test', {:payment_api => payment_api, :tenant_user_api => tenant_api}) }
  let(:logger) do
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO
    logger
  end

  before(:each) do
    @kb_account_id = SecureRandom.uuid
    @kb_payment_id = SecureRandom.uuid
    @kb_payment_method_id = SecureRandom.uuid

    @amount_in_cents = rand(100000)
    @currency = 'USD'
    @call_context = Killbill::Plugin::Model::CallContext.new
    @call_context.tenant_id = SecureRandom.uuid

    token = ::Killbill::Plugin::Model::PluginProperty.new
    token.key = 'token'
    token.value = SecureRandom.uuid
    @payment_method_props = ::Killbill::Plugin::Model::PaymentMethodPlugin.new
    @payment_method_props.properties = [token]
  end

  context 'when skipping the gateway' do
    let(:plugin) do
      plugin = ::Killbill::Plugin::ActiveMerchant::PaymentPlugin.new(Proc.new { |config| nil },
                                                                     :test,
                                                                     ::Killbill::Test::TestPaymentMethod,
                                                                     ::Killbill::Test::TestTransaction,
                                                                     ::Killbill::Test::TestResponse)
      plugin.kb_apis = kb_apis
      plugin.logger = logger

      plugin_config = {
          :test => [
              {:account_id => 'default', :test => true},
              {:account_id => 'something_non_standard', :test => true}
          ]
      }
      with_plugin_yaml_config('test.yml', plugin_config) do |file|
        plugin.conf_dir = File.dirname(file)
        plugin.root = File.dirname(file)

        # Start the plugin here - since the config file will be deleted
        plugin.start_plugin
      end

      plugin
    end

    before(:each) do
      property = ::Killbill::Plugin::Model::PluginProperty.new
      property.key = 'skip_gw'
      property.value = 'true'
      @properties = [property]

      @ppai = ::Killbill::Plugin::Model::PluginProperty.new
      @ppai.key = 'payment_processor_account_id'
      @ppai.value = 'something_non_standard'
      @properties_with_ppai = @properties.dup
      @properties_with_ppai << @ppai
    end

    after(:all) do
      plugin.stop_plugin
    end

    it 'should implement payment plugin API calls' do
      plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context).size.should == 0

      plugin.add_payment_method(@kb_account_id, @kb_payment_method_id, @payment_method_props, true, @properties, @call_context)
      plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context).size.should == 1
      ::Killbill::Test::TestPaymentMethod.where(:kb_payment_method_id => @kb_payment_method_id).first.token.should == @payment_method_props.properties[0].value

      authorization_id = SecureRandom.uuid
      payment_api.add_payment(@kb_payment_id, authorization_id, SecureRandom.uuid, :AUTHORIZE)
      authorization = plugin.authorize_payment(@kb_account_id, @kb_payment_id, authorization_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context)
      verify_transaction_info_plugin(authorization, authorization_id, :AUTHORIZE, 1)

      capture_id = SecureRandom.uuid
      payment_api.add_payment(@kb_payment_id, capture_id, SecureRandom.uuid, :CAPTURE)
      capture = plugin.capture_payment(@kb_account_id, @kb_payment_id, capture_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context)
      verify_transaction_info_plugin(capture, capture_id, :CAPTURE, 2)

      purchase_id = SecureRandom.uuid
      payment_api.add_payment(@kb_payment_id, purchase_id, SecureRandom.uuid, :PURCHASE)
      purchase = plugin.purchase_payment(@kb_account_id, @kb_payment_id, purchase_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context)
      verify_transaction_info_plugin(purchase, purchase_id, :PURCHASE, 3)

      void_id = SecureRandom.uuid
      payment_api.add_payment(@kb_payment_id, void_id, SecureRandom.uuid, :VOID)
      void = plugin.void_payment(@kb_account_id, @kb_payment_id, void_id, @kb_payment_method_id, @properties, @call_context)
      verify_transaction_info_plugin(void, void_id, :VOID, 4)

      credit_id = SecureRandom.uuid
      payment_api.add_payment(@kb_payment_id, credit_id, SecureRandom.uuid, :CREDIT)
      credit = plugin.credit_payment(@kb_account_id, @kb_payment_id, credit_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context)
      verify_transaction_info_plugin(credit, credit_id, :CREDIT, 5)

      refund_id = SecureRandom.uuid
      payment_api.add_payment(@kb_payment_id, refund_id, SecureRandom.uuid, :REFUND)
      refund = plugin.refund_payment(@kb_account_id, @kb_payment_id, refund_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context)
      verify_transaction_info_plugin(refund, refund_id, :REFUND, 6)

      plugin.delete_payment_method(@kb_account_id, @kb_payment_method_id, @properties, @call_context)
      plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context).size.should == 0
    end

    it 'should support different payment_processor_account_ids' do
      plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context).size.should == 0

      plugin.add_payment_method(@kb_account_id, @kb_payment_method_id, @payment_method_props, true, @properties, @call_context)
      plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context).size.should == 1
      ::Killbill::Test::TestPaymentMethod.where(:kb_payment_method_id => @kb_payment_method_id).first.token.should == @payment_method_props.properties[0].value

      authorization_id = SecureRandom.uuid
      payment_api.add_payment(@kb_payment_id, authorization_id, SecureRandom.uuid, :AUTHORIZE)
      authorization = plugin.authorize_payment(@kb_account_id, @kb_payment_id, authorization_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties_with_ppai, @call_context)
      verify_transaction_info_plugin(authorization, authorization_id, :AUTHORIZE, 1, @ppai.value)

      capture_id = SecureRandom.uuid
      payment_api.add_payment(@kb_payment_id, capture_id, SecureRandom.uuid, :CAPTURE)
      # We omit the payment_processor_account_id to verify we can retrieve it
      capture = plugin.capture_payment(@kb_account_id, @kb_payment_id, capture_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context)
      verify_transaction_info_plugin(capture, capture_id, :CAPTURE, 2, @ppai.value)
    end

    it 'should support storing a credit card' do
      plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context).size.should == 0

      properties = []
      properties << create_pm_kv_info('ccNumber', '41111111111111111')
      properties << create_pm_kv_info('ccFirstName', 'Paul')
      properties << create_pm_kv_info('ccLastName', 'Dupond')
      properties << create_pm_kv_info('ccType', 'visa')
      properties << create_pm_kv_info('ccExpirationMonth', '12')
      properties << create_pm_kv_info('ccExpirationYear', '17')
      payment_method_props = ::Killbill::Plugin::Model::PaymentMethodPlugin.new
      payment_method_props.properties = properties
      plugin.add_payment_method(@kb_account_id, SecureRandom.uuid, payment_method_props, true, @properties, @call_context)

      pms = plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context)
      pms.size.should == 1
      pm = plugin.get_payment_method_detail(@kb_account_id, pms[0].payment_method_id, @properties, @call_context)
      plugin.find_value_from_properties(pm.properties, 'token').should be_nil
      plugin.find_value_from_properties(pm.properties, 'ccFirstName').should == 'Paul'
      plugin.find_value_from_properties(pm.properties, 'ccLastName').should == 'Dupond'
      plugin.find_value_from_properties(pm.properties, 'ccType').should == 'visa'
      plugin.find_value_from_properties(pm.properties, 'ccExpirationMonth').should == '12'
      plugin.find_value_from_properties(pm.properties, 'ccExpirationYear').should == '17'
      plugin.find_value_from_properties(pm.properties, 'ccLast4').should == '1111'
      plugin.find_value_from_properties(pm.properties, 'ccNumber').should == '41111111111111111'

      # Verify we can retrieve the payment source, during the payment call
      source = plugin.get_payment_source(pm.kb_payment_method_id, [], {}, @call_context)
      source.is_a?(::ActiveMerchant::Billing::CreditCard).should be_true
      source.first_name.should == 'Paul'
      source.last_name.should == 'Dupond'
      source.brand.should == 'visa'
      source.month.should == 12
      source.year.should == 17
      source.number.should == '41111111111111111'
    end

    it 'should support storing a token' do
      plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context).size.should == 0

      properties = []
      properties << create_pm_kv_info('token', 'ABCDEF')
      payment_method_props = ::Killbill::Plugin::Model::PaymentMethodPlugin.new
      payment_method_props.properties = properties
      plugin.add_payment_method(@kb_account_id, SecureRandom.uuid, payment_method_props, true, @properties, @call_context)

      pms = plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context)
      pms.size.should == 1
      pm = plugin.get_payment_method_detail(@kb_account_id, pms[0].payment_method_id, @properties, @call_context)
      plugin.find_value_from_properties(pm.properties, 'token').should == 'ABCDEF'
      plugin.find_value_from_properties(pm.properties, 'ccFirstName').should be_nil
      plugin.find_value_from_properties(pm.properties, 'ccLastName').should be_nil
      plugin.find_value_from_properties(pm.properties, 'ccType').should be_nil
      plugin.find_value_from_properties(pm.properties, 'ccExpirationMonth').should be_nil
      plugin.find_value_from_properties(pm.properties, 'ccExpirationYear').should be_nil
      plugin.find_value_from_properties(pm.properties, 'ccLast4').should be_nil
      plugin.find_value_from_properties(pm.properties, 'ccNumber').should be_nil

      # Verify we can retrieve the payment source, during the payment call
      source = plugin.get_payment_source(pm.kb_payment_method_id, [], {}, @call_context)
      source.should == 'ABCDEF'
    end

    it 'should support storing a placeholder row' do
      plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context).size.should == 0

      plugin.add_payment_method(@kb_account_id, SecureRandom.uuid, ::Killbill::Plugin::Model::PaymentMethodPlugin.new, true, @properties, @call_context)

      pms = plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context)
      pms.size.should == 1
      pm = plugin.get_payment_method_detail(@kb_account_id, pms[0].payment_method_id, @properties, @call_context)
      plugin.find_value_from_properties(pm.properties, 'token').should be_nil
      plugin.find_value_from_properties(pm.properties, 'ccFirstName').should be_nil
      plugin.find_value_from_properties(pm.properties, 'ccLastName').should be_nil
      plugin.find_value_from_properties(pm.properties, 'ccType').should be_nil
      plugin.find_value_from_properties(pm.properties, 'ccExpirationMonth').should be_nil
      plugin.find_value_from_properties(pm.properties, 'ccExpirationYear').should be_nil
      plugin.find_value_from_properties(pm.properties, 'ccLast4').should be_nil
      plugin.find_value_from_properties(pm.properties, 'ccNumber').should be_nil

      # Verify we can retrieve the payment source, during the payment call
      source = plugin.get_payment_source(pm.kb_payment_method_id, [], {}, @call_context)
      source.is_a?(::ActiveMerchant::Billing::CreditCard).should be_true
      source.first_name.should be_nil
      source.last_name.should be_nil
      source.brand.should be_nil
      source.month.should be_nil
      source.year.should be_nil
      source.number.should be_nil
    end

    it 'recognizes a tokenized card by the network' do
      options = {
          :cc_number => '4242424242424242',
          :cc_type => 'visa',
          :cc_expiration_month => 12,
          :cc_expiration_year => 2019,
          :payment_cryptogram => 'EHuWW9PiBkWvqE5juRwDzAUFBAk=',
          :eci => '05'
      }
      source = plugin.get_payment_source(nil, [], options, @call_context)
      source.is_a?(::ActiveMerchant::Billing::NetworkTokenizationCreditCard).should be_true
      source.type.should == 'network_tokenization'
      source.number.should == '4242424242424242'
      source.brand.should == 'visa'
      source.month.should == 12
      source.year.should == 2019
      source.payment_cryptogram.should == 'EHuWW9PiBkWvqE5juRwDzAUFBAk='
      source.eci.should == '05'
    end

    it 'recognizes an ApplePay token' do
      options = {
          :token => '{"data":"BDPNWStMmGewQUWGg4o7E/j+1cq1T78qyU84b67itjcYI8wPYAOhshjhZPrqdUr4XwPMbj4zcGMdy++1H2VkPOY+BOMF25ub19cX4nCvkXUUOTjDllB1TgSr8JHZxgp9rCgsSUgbBgKf60XKutXf6aj/o8ZIbKnrKQ8Sh0ouLAKloUMn+vPu4+A7WKrqrauz9JvOQp6vhIq+HKjUcUNCITPyFhmOEtq+H+w0vRa1CE6WhFBNnCHqzzWKckB/0nqLZRTYbF0p+vyBiVaWHeghERfHxRtbzpeczRPPuFsfpHVs48oPLC/k/1MNd47kz/pHDcR/Dy6aUM+lNfoily/QJN+tS3m0HfOtISAPqOmXemvr6xJCjCZlCuw0C9mXz/obHpofuIES8r9cqGGsUAPDpw7g642m4PzwKF+HBuYUneWDBNSD2u6jbAG3","version":"EC_v1","header":{"applicationData":"94ee059335e587e501cc4bf90613e0814f00a7b08bc7c648fd865a2af6a22cc2","transactionId":"c1caf5ae72f0039a82bad92b828363734f85bf2f9cadf193d1bad9ddcb60a795","ephemeralPublicKey":"MIIBSzCCAQMGByqGSM49AgEwgfcCAQEwLAYHKoZIzj0BAQIhAP////8AAAABAAAAAAAAAAAAAAAA////////////////MFsEIP////8AAAABAAAAAAAAAAAAAAAA///////////////8BCBaxjXYqjqT57PrvVV2mIa8ZR0GsMxTsPY7zjw+J9JgSwMVAMSdNgiG5wSTamZ44ROdJreBn36QBEEEaxfR8uEsQkf4vOblY6RA8ncDfYEt6zOg9KE5RdiYwpZP40Li/hp/m47n60p8D54WK84zV2sxXs7LtkBoN79R9QIhAP////8AAAAA//////////+85vqtpxeehPO5ysL8YyVRAgEBA0IABGm+gsl0PZFT/kDdUSkxwyfo8JpwTQQzBm9lJJnmTl4DGUvAD4GseGj/pshBZ0K3TeuqDt/tDLbE+8/m0yCmoxw=","publicKeyHash":"/bb9CNC36uBheHFPbmohB7Oo1OsX2J+kJqv48zOVViQ="},"signature":"MIIDQgYJKoZIhvcNAQcCoIIDMzCCAy8CAQExCzAJBgUrDgMCGgUAMAsGCSqGSIb3DQEHAaCCAiswggInMIIBlKADAgECAhBcl+Pf3+U4pk13nVD9nwQQMAkGBSsOAwIdBQAwJzElMCMGA1UEAx4cAGMAaABtAGEAaQBAAHYAaQBzAGEALgBjAG8AbTAeFw0xNDAxMDEwNjAwMDBaFw0yNDAxMDEwNjAwMDBaMCcxJTAjBgNVBAMeHABjAGgAbQBhAGkAQAB2AGkAcwBhAC4AYwBvAG0wgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBANC8+kgtgmvWF1OzjgDNrjTEBRuo/5MKvlM146pAf7Gx41blE9w4fIXJAD7FfO7QKjIXYNt39rLyy7xDwb/5IkZM60TZ2iI1pj55Uc8fd4fzOpk3ftZaQGXNLYptG1d9V7IS82Oup9MMo1BPVrXTPHNcsM99EPUnPqdbeGc87m0rAgMBAAGjXDBaMFgGA1UdAQRRME+AEHZWPrWtJd7YZ431hCg7YFShKTAnMSUwIwYDVQQDHhwAYwBoAG0AYQBpAEAAdgBpAHMAYQAuAGMAbwBtghBcl+Pf3+U4pk13nVD9nwQQMAkGBSsOAwIdBQADgYEAbUKYCkuIKS9QQ2mFcMYREIm2l+Xg8/JXv+GBVQJkOKoscY4iNDFA/bQlogf9LLU84THwNRnsvV3Prv7RTY81gq0dtC8zYcAaAkCHII3yqMnJ4AOu6EOW9kJk232gSE7WlCtHbfLSKfuSgQX8KXQYuZLk2Rr63N8ApXsXwBL3cJ0xgeAwgd0CAQEwOzAnMSUwIwYDVQQDHhwAYwBoAG0AYQBpAEAAdgBpAHMAYQAuAGMAbwBtAhBcl+Pf3+U4pk13nVD9nwQQMAkGBSsOAwIaBQAwDQYJKoZIhvcNAQEBBQAEgYBaK3ElOstbH8WooseDABf+Jg/129JcIawm7c6Vxn7ZasNbAq3tAt8Pty+uQCgssXqZkLA7kz2GzMolNtv9wYmu9Ujwar1PHYS+B/oGnoz591wjagXWRz0nMo5y3O1KzX0d8CRHAVa88SrV1a5JIiRev3oStIqwv5xuZldag6Tr8w=="}',
          :payment_instrument_name => 'SomeBank Points Card',
          :payment_network => 'MasterCard',
          :transaction_identifier => 'uniqueidentifier123'
      }
      source = plugin.get_payment_source(nil, [], options, @call_context)
      source.is_a?(::ActiveMerchant::Billing::ApplePayPaymentToken).should be_true
      source.type.should == 'apple_pay'
      source.payment_instrument_name.should == 'SomeBank Points Card'
      source.payment_network.should == 'MasterCard'
      # Not set in ApplePayPaymentToken?
      #source.transaction_identifier.should == 'uniqueidentifier123'
      source.payment_data.should == {
          'data' => 'BDPNWStMmGewQUWGg4o7E/j+1cq1T78qyU84b67itjcYI8wPYAOhshjhZPrqdUr4XwPMbj4zcGMdy++1H2VkPOY+BOMF25ub19cX4nCvkXUUOTjDllB1TgSr8JHZxgp9rCgsSUgbBgKf60XKutXf6aj/o8ZIbKnrKQ8Sh0ouLAKloUMn+vPu4+A7WKrqrauz9JvOQp6vhIq+HKjUcUNCITPyFhmOEtq+H+w0vRa1CE6WhFBNnCHqzzWKckB/0nqLZRTYbF0p+vyBiVaWHeghERfHxRtbzpeczRPPuFsfpHVs48oPLC/k/1MNd47kz/pHDcR/Dy6aUM+lNfoily/QJN+tS3m0HfOtISAPqOmXemvr6xJCjCZlCuw0C9mXz/obHpofuIES8r9cqGGsUAPDpw7g642m4PzwKF+HBuYUneWDBNSD2u6jbAG3',
          'version' => 'EC_v1',
          'header' => {
              'applicationData' => '94ee059335e587e501cc4bf90613e0814f00a7b08bc7c648fd865a2af6a22cc2',
              'transactionId' => 'c1caf5ae72f0039a82bad92b828363734f85bf2f9cadf193d1bad9ddcb60a795',
              'ephemeralPublicKey' => 'MIIBSzCCAQMGByqGSM49AgEwgfcCAQEwLAYHKoZIzj0BAQIhAP////8AAAABAAAAAAAAAAAAAAAA////////////////MFsEIP////8AAAABAAAAAAAAAAAAAAAA///////////////8BCBaxjXYqjqT57PrvVV2mIa8ZR0GsMxTsPY7zjw+J9JgSwMVAMSdNgiG5wSTamZ44ROdJreBn36QBEEEaxfR8uEsQkf4vOblY6RA8ncDfYEt6zOg9KE5RdiYwpZP40Li/hp/m47n60p8D54WK84zV2sxXs7LtkBoN79R9QIhAP////8AAAAA//////////+85vqtpxeehPO5ysL8YyVRAgEBA0IABGm+gsl0PZFT/kDdUSkxwyfo8JpwTQQzBm9lJJnmTl4DGUvAD4GseGj/pshBZ0K3TeuqDt/tDLbE+8/m0yCmoxw=',
              'publicKeyHash' => '/bb9CNC36uBheHFPbmohB7Oo1OsX2J+kJqv48zOVViQ='
          },
          'signature' => 'MIIDQgYJKoZIhvcNAQcCoIIDMzCCAy8CAQExCzAJBgUrDgMCGgUAMAsGCSqGSIb3DQEHAaCCAiswggInMIIBlKADAgECAhBcl+Pf3+U4pk13nVD9nwQQMAkGBSsOAwIdBQAwJzElMCMGA1UEAx4cAGMAaABtAGEAaQBAAHYAaQBzAGEALgBjAG8AbTAeFw0xNDAxMDEwNjAwMDBaFw0yNDAxMDEwNjAwMDBaMCcxJTAjBgNVBAMeHABjAGgAbQBhAGkAQAB2AGkAcwBhAC4AYwBvAG0wgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBANC8+kgtgmvWF1OzjgDNrjTEBRuo/5MKvlM146pAf7Gx41blE9w4fIXJAD7FfO7QKjIXYNt39rLyy7xDwb/5IkZM60TZ2iI1pj55Uc8fd4fzOpk3ftZaQGXNLYptG1d9V7IS82Oup9MMo1BPVrXTPHNcsM99EPUnPqdbeGc87m0rAgMBAAGjXDBaMFgGA1UdAQRRME+AEHZWPrWtJd7YZ431hCg7YFShKTAnMSUwIwYDVQQDHhwAYwBoAG0AYQBpAEAAdgBpAHMAYQAuAGMAbwBtghBcl+Pf3+U4pk13nVD9nwQQMAkGBSsOAwIdBQADgYEAbUKYCkuIKS9QQ2mFcMYREIm2l+Xg8/JXv+GBVQJkOKoscY4iNDFA/bQlogf9LLU84THwNRnsvV3Prv7RTY81gq0dtC8zYcAaAkCHII3yqMnJ4AOu6EOW9kJk232gSE7WlCtHbfLSKfuSgQX8KXQYuZLk2Rr63N8ApXsXwBL3cJ0xgeAwgd0CAQEwOzAnMSUwIwYDVQQDHhwAYwBoAG0AYQBpAEAAdgBpAHMAYQAuAGMAbwBtAhBcl+Pf3+U4pk13nVD9nwQQMAkGBSsOAwIaBQAwDQYJKoZIhvcNAQEBBQAEgYBaK3ElOstbH8WooseDABf+Jg/129JcIawm7c6Vxn7ZasNbAq3tAt8Pty+uQCgssXqZkLA7kz2GzMolNtv9wYmu9Ujwar1PHYS+B/oGnoz591wjagXWRz0nMo5y3O1KzX0d8CRHAVa88SrV1a5JIiRev3oStIqwv5xuZldag6Tr8w=='
      }
    end

    # Apple Pay integration with CyberSource for example
    it 'merges tokenized cards with payment method information' do
      # Create a payment method with just a first and last name
      cc_first_name = ::Killbill::Plugin::Model::PluginProperty.new
      cc_first_name.key = 'cc_first_name'
      cc_first_name.value = 'John'
      cc_last_name = ::Killbill::Plugin::Model::PluginProperty.new
      cc_last_name.key = 'cc_last_name'
      cc_last_name.value = 'Doe'
      skip_gw = ::Killbill::Plugin::Model::PluginProperty.new
      skip_gw.key = 'skip_gw'
      skip_gw.value = 'true'
      pm_properties = ::Killbill::Plugin::Model::PaymentMethodPlugin.new
      plugin.add_payment_method(@kb_account_id, @kb_payment_method_id, pm_properties, true, [skip_gw, cc_first_name, cc_last_name], @call_context)

      # Build the NetworkTokenizationCreditCard
      options = {
          :cc_number => '4242424242424242',
          :cc_type => 'visa',
          :cc_expiration_month => 12,
          :cc_expiration_year => 2019,
          :payment_cryptogram => 'EHuWW9PiBkWvqE5juRwDzAUFBAk=',
          :eci => '05'
      }
      source = plugin.get_payment_source(@kb_payment_method_id, [], options, @call_context)
      source.is_a?(::ActiveMerchant::Billing::NetworkTokenizationCreditCard).should be_true
      source.type.should == 'network_tokenization'
      source.number.should == '4242424242424242'
      source.brand.should == 'visa'
      source.month.should == 12
      source.year.should == 2019
      source.payment_cryptogram.should == 'EHuWW9PiBkWvqE5juRwDzAUFBAk='
      source.eci.should == '05'
      # The first and last name should have been populated from the payment method
      source.first_name.should == 'John'
      source.last_name.should == 'Doe'
    end
  end

  context 'with a dummy gateway' do
    let(:gateway) { DummyRecordingGateway.new }

    let(:plugin) do
      plugin = ::Killbill::Plugin::ActiveMerchant::PaymentPlugin.new(Proc.new { |config| gateway },
                                                                     :test,
                                                                     ::Killbill::Test::TestPaymentMethod,
                                                                     ::Killbill::Test::TestTransaction,
                                                                     ::Killbill::Test::TestResponse)
      plugin.kb_apis = kb_apis
      plugin.logger = logger

      plugin_config = {
          :test => [
              {:account_id => 'default', :test => true},
          ]
      }
      with_plugin_yaml_config('test.yml', plugin_config) do |file|
        plugin.conf_dir = File.dirname(file)
        plugin.root = File.dirname(file)

        # Start the plugin here - since the config file will be deleted
        plugin.start_plugin
      end

      plugin
    end

    after(:each) do
      gateway.call_stack.clear
    end

    after(:all) do
      plugin.stop_plugin
    end

    it 'sets the kb_payment_transaction_id as order_id by default' do
      plugin.add_payment_method(@kb_account_id, @kb_payment_method_id, @payment_method_props, true, [], @call_context)

      kb_payment_transaction_id = SecureRandom.uuid
      plugin.purchase_payment(@kb_account_id, @kb_payment_id, kb_payment_transaction_id, @kb_payment_method_id, @amount_in_cents, @currency, [], @call_context)

      sent_options = gateway.call_stack[-1][:options]
      sent_options.size.should == 11
      sent_options[:currency].should == @currency
      sent_options[:description].should == "Kill Bill purchase for #{kb_payment_transaction_id}"
      sent_options[:order_id].should == kb_payment_transaction_id
    end

    it 'sets the kb_payment_transaction_id as order_id if specified' do
      plugin.add_payment_method(@kb_account_id, @kb_payment_method_id, @payment_method_props, true, [], @call_context)

      property = ::Killbill::Plugin::Model::PluginProperty.new
      property.key = 'external_key_as_order_id'
      property.value = 'false'

      kb_payment_transaction_id = SecureRandom.uuid
      plugin.purchase_payment(@kb_account_id, @kb_payment_id, kb_payment_transaction_id, @kb_payment_method_id, @amount_in_cents, @currency, [property], @call_context)

      sent_options = gateway.call_stack[-1][:options]
      sent_options.size.should == 12
      sent_options[:currency].should == @currency
      sent_options[:description].should == "Kill Bill purchase for #{kb_payment_transaction_id}"
      sent_options[:order_id].should == kb_payment_transaction_id
    end

    it 'sets the payment transaction external key as order_id if specified' do
      plugin.add_payment_method(@kb_account_id, @kb_payment_method_id, @payment_method_props, true, [], @call_context)

      property = ::Killbill::Plugin::Model::PluginProperty.new
      property.key = 'external_key_as_order_id'
      property.value = 'true'

      kb_payment_transaction_id = SecureRandom.uuid
      kb_payment_transaction_external_key = SecureRandom.uuid
      payment_api.add_payment(@kb_payment_id,  kb_payment_transaction_id, kb_payment_transaction_external_key, :PURCHASE)
      plugin.purchase_payment(@kb_account_id, @kb_payment_id, kb_payment_transaction_id, @kb_payment_method_id, @amount_in_cents, @currency, [property], @call_context)

      sent_options = gateway.call_stack[-1][:options]
      sent_options.size.should == 12
      sent_options[:currency].should == @currency
      sent_options[:description].should == "Kill Bill purchase for #{kb_payment_transaction_id}"
      sent_options[:order_id].should == kb_payment_transaction_external_key
    end
  end

  private

  def verify_transaction_info_plugin(t_info_plugin, kb_transaction_id, type, transaction_nb, payment_processor_account_id='default')
    t_info_plugin.kb_payment_id.should == @kb_payment_id
    t_info_plugin.kb_transaction_payment_id.should == kb_transaction_id
    t_info_plugin.transaction_type.should == type
    if type == :VOID
      t_info_plugin.amount.should be_nil
      t_info_plugin.currency.should be_nil
    else
      t_info_plugin.amount.should == @amount_in_cents
      t_info_plugin.currency.should == @currency
    end
    t_info_plugin.status.should == :PROCESSED

    # Verify we routed to the right gateway
    (t_info_plugin.properties.find { |kv| kv.key.to_s == 'payment_processor_account_id' }).value.to_s.should == payment_processor_account_id

    transactions = plugin.get_payment_info(@kb_account_id, @kb_payment_id, [], @call_context)
    transactions.size.should == transaction_nb
    transactions[transaction_nb - 1].to_json.should == t_info_plugin.to_json
  end

  class DummyRecordingGateway < ::ActiveMerchant::Billing::Gateway

    attr_reader :call_stack

    def initialize
      @call_stack = []
    end

    def purchase(money, paysource, options = {})
      @call_stack << {:money => money, :source => paysource, :options => options}
      ::ActiveMerchant::Billing::Response.new(true, 'Success!', {:authorized_amount => money}, :test => true, :authorization => 12345)
    end

    def store(paysource, options = {})
      @call_stack << {:source => paysource, :options => options}
      ::ActiveMerchant::Billing::Response.new(true, 'Success!', {:billingid => '1'}, :test => true, :authorization => 12345)
    end
  end
end
