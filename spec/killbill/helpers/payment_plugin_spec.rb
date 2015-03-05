require 'spec_helper'
require 'spec/killbill/helpers/payment_method_spec'
require 'spec/killbill/helpers/response_spec'
require 'spec/killbill/helpers/transaction_spec'

describe Killbill::Plugin::ActiveMerchant::PaymentPlugin do
  include Killbill::Plugin::ActiveMerchant::RSpec

  before(:all) do
    plugin_config = {
      :test => [
        { :account_id => "default", :test => true },
        { :account_id => "something_non_standard", :test => true }
      ]
    }
    with_plugin_yaml_config('test.yml', plugin_config) do |file|
      @plugin              = ::Killbill::Plugin::ActiveMerchant::PaymentPlugin.new(Proc.new { |config| nil },
                                                                                   :test,
                                                                                   ::Killbill::Test::TestPaymentMethod,
                                                                                   ::Killbill::Test::TestTransaction,
                                                                                   ::Killbill::Test::TestResponse)
      @payment_api         = ::Killbill::Plugin::ActiveMerchant::RSpec::FakeJavaPaymentApi.new
      @plugin.kb_apis      = ::Killbill::Plugin::KillbillApi.new('test', {:payment_api => @payment_api})
      @plugin.logger       = Logger.new(STDOUT)
      @plugin.logger.level = Logger::INFO
      @plugin.conf_dir     = File.dirname(file)

      # Start the plugin here - since the config file will be deleted
      @plugin.start_plugin
    end
  end

  before(:each) do
    @kb_account_id        = SecureRandom.uuid
    @kb_payment_id        = SecureRandom.uuid
    @kb_payment_method_id = SecureRandom.uuid

    @amount_in_cents        = rand(100000)
    @currency               = 'USD'
    @call_context           = Killbill::Plugin::Model::CallContext.new
    @call_context.tenant_id = SecureRandom.uuid

    property       = ::Killbill::Plugin::Model::PluginProperty.new
    property.key   = 'skip_gw'
    property.value = 'true'
    @properties    = [property]

    @ppai                 = ::Killbill::Plugin::Model::PluginProperty.new
    @ppai.key             = 'payment_processor_account_id'
    @ppai.value           = 'something_non_standard'
    @properties_with_ppai = @properties.dup
    @properties_with_ppai << @ppai

    token                            = ::Killbill::Plugin::Model::PluginProperty.new
    token.key                        = 'token'
    token.value                      = SecureRandom.uuid
    @payment_method_props            = ::Killbill::Plugin::Model::PaymentMethodPlugin.new
    @payment_method_props.properties = [token]
  end

  after(:all) do
    @plugin.stop_plugin
  end

  it 'should implement payment plugin API calls' do
    @plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context).size.should == 0

    @plugin.add_payment_method(@kb_account_id, @kb_payment_method_id, @payment_method_props, true, @properties, @call_context)
    @plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context).size.should == 1
    ::Killbill::Test::TestPaymentMethod.where(:kb_payment_method_id => @kb_payment_method_id).first.token.should == @payment_method_props.properties[0].value

    authorization_id = SecureRandom.uuid
    @payment_api.add_payment(@kb_payment_id, authorization_id, SecureRandom.uuid, :AUTHORIZE)
    authorization = @plugin.authorize_payment(@kb_account_id, @kb_payment_id, authorization_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context)
    verify_transaction_info_plugin(authorization, authorization_id, :AUTHORIZE, 1)

    capture_id = SecureRandom.uuid
    @payment_api.add_payment(@kb_payment_id, capture_id, SecureRandom.uuid, :CAPTURE)
    capture = @plugin.capture_payment(@kb_account_id, @kb_payment_id, capture_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context)
    verify_transaction_info_plugin(capture, capture_id, :CAPTURE, 2)

    purchase_id = SecureRandom.uuid
    @payment_api.add_payment(@kb_payment_id, purchase_id, SecureRandom.uuid, :PURCHASE)
    purchase = @plugin.purchase_payment(@kb_account_id, @kb_payment_id, purchase_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context)
    verify_transaction_info_plugin(purchase, purchase_id, :PURCHASE, 3)

    void_id = SecureRandom.uuid
    @payment_api.add_payment(@kb_payment_id, void_id, SecureRandom.uuid, :VOID)
    void = @plugin.void_payment(@kb_account_id, @kb_payment_id, void_id, @kb_payment_method_id, @properties, @call_context)
    verify_transaction_info_plugin(void, void_id, :VOID, 4)

    credit_id = SecureRandom.uuid
    @payment_api.add_payment(@kb_payment_id, credit_id, SecureRandom.uuid, :CREDIT)
    credit = @plugin.credit_payment(@kb_account_id, @kb_payment_id, credit_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context)
    verify_transaction_info_plugin(credit, credit_id, :CREDIT, 5)

    refund_id = SecureRandom.uuid
    @payment_api.add_payment(@kb_payment_id, refund_id, SecureRandom.uuid, :REFUND)
    refund = @plugin.refund_payment(@kb_account_id, @kb_payment_id, refund_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context)
    verify_transaction_info_plugin(refund, refund_id, :REFUND, 6)

    @plugin.delete_payment_method(@kb_account_id, @kb_payment_method_id, @properties, @call_context)
    @plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context).size.should == 0
  end

  it 'should support different payment_processor_account_ids' do
    @plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context).size.should == 0

    @plugin.add_payment_method(@kb_account_id, @kb_payment_method_id, @payment_method_props, true, @properties, @call_context)
    @plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context).size.should == 1
    ::Killbill::Test::TestPaymentMethod.where(:kb_payment_method_id => @kb_payment_method_id).first.token.should == @payment_method_props.properties[0].value

    authorization_id = SecureRandom.uuid
    @payment_api.add_payment(@kb_payment_id, authorization_id, SecureRandom.uuid, :AUTHORIZE)
    authorization = @plugin.authorize_payment(@kb_account_id, @kb_payment_id, authorization_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties_with_ppai, @call_context)
    verify_transaction_info_plugin(authorization, authorization_id, :AUTHORIZE, 1, @ppai.value)

    capture_id = SecureRandom.uuid
    @payment_api.add_payment(@kb_payment_id, capture_id, SecureRandom.uuid, :CAPTURE)
    # We omit the payment_processor_account_id to verify we can retrieve it
    capture = @plugin.capture_payment(@kb_account_id, @kb_payment_id, capture_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context)
    verify_transaction_info_plugin(capture, capture_id, :CAPTURE, 2, @ppai.value)
  end

  it 'should support storing a credit card' do
    @plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context).size.should == 0

    properties = []
    properties << create_pm_kv_info('ccNumber', '41111111111111111')
    properties << create_pm_kv_info('ccFirstName', 'Paul')
    properties << create_pm_kv_info('ccLastName', 'Dupond')
    properties << create_pm_kv_info('ccType', 'VISA')
    properties << create_pm_kv_info('ccExpirationMonth', '12')
    properties << create_pm_kv_info('ccExpirationYear', '17')
    payment_method_props            = ::Killbill::Plugin::Model::PaymentMethodPlugin.new
    payment_method_props.properties = properties
    @plugin.add_payment_method(@kb_account_id, SecureRandom.uuid, payment_method_props, true, @properties, @call_context)

    pms = @plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context)
    pms.size.should == 1
    pm = @plugin.get_payment_method_detail(@kb_account_id, pms[0].payment_method_id, @properties, @call_context)
    @plugin.find_value_from_properties(pm.properties, 'token').should be_nil
    @plugin.find_value_from_properties(pm.properties, 'ccFirstName').should == 'Paul'
    @plugin.find_value_from_properties(pm.properties, 'ccLastName').should == 'Dupond'
    @plugin.find_value_from_properties(pm.properties, 'ccType').should == 'visa'
    @plugin.find_value_from_properties(pm.properties, 'ccExpirationMonth').should == '12'
    @plugin.find_value_from_properties(pm.properties, 'ccExpirationYear').should == '17'
    @plugin.find_value_from_properties(pm.properties, 'ccLast4').should == '1111'
    @plugin.find_value_from_properties(pm.properties, 'ccNumber').should == '41111111111111111'

    # Verify we can retrieve the payment source, during the payment call
    source = @plugin.get_payment_source(pm.kb_payment_method_id, [], {}, @call_context)
    source.is_a?(::ActiveMerchant::Billing::CreditCard).should be_true
    source.first_name.should == 'Paul'
    source.last_name.should == 'Dupond'
    source.brand.should == 'visa'
    source.month.should == 12
    source.year.should == 17
    source.number.should == '41111111111111111'
  end

  it 'should support storing a token' do
    @plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context).size.should == 0

    properties = []
    properties << create_pm_kv_info('token', 'ABCDEF')
    payment_method_props            = ::Killbill::Plugin::Model::PaymentMethodPlugin.new
    payment_method_props.properties = properties
    @plugin.add_payment_method(@kb_account_id, SecureRandom.uuid, payment_method_props, true, @properties, @call_context)

    pms = @plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context)
    pms.size.should == 1
    pm = @plugin.get_payment_method_detail(@kb_account_id, pms[0].payment_method_id, @properties, @call_context)
    @plugin.find_value_from_properties(pm.properties, 'token').should == 'ABCDEF'
    @plugin.find_value_from_properties(pm.properties, 'ccFirstName').should be_nil
    @plugin.find_value_from_properties(pm.properties, 'ccLastName').should be_nil
    @plugin.find_value_from_properties(pm.properties, 'ccType').should be_nil
    @plugin.find_value_from_properties(pm.properties, 'ccExpirationMonth').should be_nil
    @plugin.find_value_from_properties(pm.properties, 'ccExpirationYear').should be_nil
    @plugin.find_value_from_properties(pm.properties, 'ccLast4').should be_nil
    @plugin.find_value_from_properties(pm.properties, 'ccNumber').should be_nil

    # Verify we can retrieve the payment source, during the payment call
    source = @plugin.get_payment_source(pm.kb_payment_method_id, [], {}, @call_context)
    source.should == 'ABCDEF'
  end

  it 'should support storing a placeholder row' do
    @plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context).size.should == 0

    @plugin.add_payment_method(@kb_account_id, SecureRandom.uuid, ::Killbill::Plugin::Model::PaymentMethodPlugin.new, true, @properties, @call_context)

    pms = @plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context)
    pms.size.should == 1
    pm = @plugin.get_payment_method_detail(@kb_account_id, pms[0].payment_method_id, @properties, @call_context)
    @plugin.find_value_from_properties(pm.properties, 'token').should be_nil
    @plugin.find_value_from_properties(pm.properties, 'ccFirstName').should be_nil
    @plugin.find_value_from_properties(pm.properties, 'ccLastName').should be_nil
    @plugin.find_value_from_properties(pm.properties, 'ccType').should be_nil
    @plugin.find_value_from_properties(pm.properties, 'ccExpirationMonth').should be_nil
    @plugin.find_value_from_properties(pm.properties, 'ccExpirationYear').should be_nil
    @plugin.find_value_from_properties(pm.properties, 'ccLast4').should be_nil
    @plugin.find_value_from_properties(pm.properties, 'ccNumber').should be_nil

    # Verify we can retrieve the payment source, during the payment call
    source = @plugin.get_payment_source(pm.kb_payment_method_id, [], {}, @call_context)
    source.is_a?(::ActiveMerchant::Billing::CreditCard).should be_true
    source.first_name.should be_nil
    source.last_name.should be_nil
    source.brand.should be_nil
    source.month.should be_nil
    source.year.should be_nil
    source.number.should be_nil
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

    transactions = @plugin.get_payment_info(@kb_account_id, @kb_payment_id, [], @call_context)
    transactions.size.should == transaction_nb
    transactions[transaction_nb - 1].to_json.should == t_info_plugin.to_json
  end
end
