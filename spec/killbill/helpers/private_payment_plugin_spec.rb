require 'spec_helper'
require 'spec/killbill/helpers/payment_method_spec'
require 'spec/killbill/helpers/response_spec'
require 'spec/killbill/helpers/transaction_spec'

describe Killbill::Plugin::ActiveMerchant::PrivatePaymentPlugin do

  before(:each) do
    @order_id   = SecureRandom.uuid
    @account_id = SecureRandom.uuid
    @options    = {:amount => 120, :country => 'US', :forward_url => 'http://kill-bill.org', :html => {:authenticity_token => false}}
    @session    = {:foo => :bar}

    setup_public_plugin

    @plugin = Killbill::Plugin::ActiveMerchant::PrivatePaymentPlugin.new(:test,
                                                                         ::Killbill::Test::TestPaymentMethod,
                                                                         ::Killbill::Test::TestTransaction,
                                                                         ::Killbill::Test::TestResponse,
                                                                         @session)
    @plugin.session.should == @session
  end

  it 'should build payment links' do
    link = @plugin.payment_link_for('Pay!', @order_id, @account_id, :bogus, @options)
    link.should == "<a account=\"#{@account_id}\" amount=\"#{@options[:amount]}\" authenticity_token=\"false\" href=\"http://www.bogus.com?order=#{@order_id}&amp;account=#{@account_id}&amp;amount=#{@options[:amount]}\">Pay!</a>"
  end

  it 'should build payment forms' do
    form = @plugin.payment_form_for(@order_id, @account_id, :bogus, @options) do |service|
      service.token = 'Pay!'
    end
    form.should == "<form accept-charset=\"UTF-8\" action=\"http://www.bogus.com\" disable_authenticity_token=\"true\" method=\"post\"><div style=\"display:none\"></div>
Pay!
<input id=\"order\" name=\"order\" type=\"hidden\" value=\"#{@order_id}\" />
<input id=\"account\" name=\"account\" type=\"hidden\" value=\"#{@account_id}\" />
<input id=\"amount\" name=\"amount\" type=\"hidden\" value=\"#{@options[:amount]}\" />
</form>"
  end

  it 'should save responses and transactions' do
    response, transaction = @plugin.save_response_and_transaction(::ActiveMerchant::Billing::Response.new(true, 'OK'), :custom_thinggy, @account_id, SecureRandom.uuid, :default, SecureRandom.uuid, SecureRandom.uuid, :op, 1242, 'USD')

    response.api_call.should == :custom_thinggy
    transaction.transaction_type.should == :op
  end

  it 'should access global variables' do
    @plugin.kb_apis.is_a?(::Killbill::Plugin::KillbillApi).should be_true
    @plugin.gateway.is_a?(::Killbill::Plugin::ActiveMerchant::Gateway).should be_true
    @plugin.logger.respond_to?(:info).should be_true
  end

  private

  def setup_public_plugin
    with_plugin_yaml_config('test.yml', :test => { :test => true }) do |file|
      plugin          = ::Killbill::Plugin::ActiveMerchant::PaymentPlugin.new(Proc.new { |config| nil },
                                                                              :test,
                                                                              ::Killbill::Test::TestPaymentMethod,
                                                                              ::Killbill::Test::TestTransaction,
                                                                              ::Killbill::Test::TestResponse)
      payment_api     = ::Killbill::Plugin::ActiveMerchant::RSpec::FakeJavaPaymentApi.new
      plugin.kb_apis  = ::Killbill::Plugin::KillbillApi.new('test', {:payment_api => payment_api})
      plugin.logger   = Logger.new(STDOUT)
      plugin.conf_dir = File.dirname(file)

      # Start the plugin here - since the config file will be deleted
      plugin.start_plugin
    end
  end
end
