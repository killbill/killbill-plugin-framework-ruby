require 'spec_helper'
require 'spec/killbill/helpers/payment_method_spec'
require 'spec/killbill/helpers/response_spec'
require 'spec/killbill/helpers/transaction_spec'

describe Killbill::Plugin::ActiveMerchant::PaymentPlugin do

  before(:all) do
    Dir.mktmpdir do |dir|
      file = File.new(File.join(dir, 'test.yml'), "w+")
      file.write(<<-eos)
:test:
  :test: true
# As defined by spec_helper.rb
:database:
  :adapter: 'sqlite3'
  :database: 'test.db'
      eos
      file.close

      @plugin              = ::Killbill::Plugin::ActiveMerchant::PaymentPlugin.new(Proc.new { |config| nil },
                                                                                   :test,
                                                                                   ::Killbill::Test::TestPaymentMethod,
                                                                                   ::Killbill::Test::TestTransaction,
                                                                                   ::Killbill::Test::TestResponse)
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
    authorization    = @plugin.authorize_payment(@kb_account_id, @kb_payment_id, authorization_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context)
    verify_transaction_info_plugin(authorization, authorization_id, :AUTHORIZE, 1)

    capture_id = SecureRandom.uuid
    capture    = @plugin.capture_payment(@kb_account_id, @kb_payment_id, capture_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context)
    verify_transaction_info_plugin(capture, capture_id, :CAPTURE, 2)

    purchase_id = SecureRandom.uuid
    purchase    = @plugin.purchase_payment(@kb_account_id, @kb_payment_id, purchase_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context)
    verify_transaction_info_plugin(purchase, purchase_id, :PURCHASE, 3)

    void_id = SecureRandom.uuid
    void    = @plugin.void_payment(@kb_account_id, @kb_payment_id, void_id, @kb_payment_method_id, @properties, @call_context)
    verify_transaction_info_plugin(void, void_id, :VOID, 4)

    credit_id = SecureRandom.uuid
    credit    = @plugin.credit_payment(@kb_account_id, @kb_payment_id, credit_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context)
    verify_transaction_info_plugin(credit, credit_id, :CREDIT, 5)

    refund_id = SecureRandom.uuid
    refund    = @plugin.refund_payment(@kb_account_id, @kb_payment_id, refund_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context)
    verify_transaction_info_plugin(refund, refund_id, :REFUND, 6)

    @plugin.delete_payment_method(@kb_account_id, @kb_payment_method_id, @properties, @call_context)
    @plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context).size.should == 0
  end

  private

  def verify_transaction_info_plugin(t_info_plugin, kb_transaction_id, type, transaction_nb)
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

    transactions = @plugin.get_payment_info(@kb_account_id, @kb_payment_id, [], @call_context)
    transactions.size.should == transaction_nb
    transactions[transaction_nb - 1].to_json.should == t_info_plugin.to_json
  end
end
