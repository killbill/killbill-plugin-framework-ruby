require 'spec_helper'

require 'killbill/jpayment'

describe Killbill::Plugin::JPayment do

  before(:all) do
    logger = ::Logger.new(STDOUT)
    @jpayment =  Killbill::Plugin::JPayment.new("Killbill::Plugin::PaymentTest", { "logger" => logger })
    @kb_account_id = java.util.UUID.fromString("aa5c926e-3d9d-4435-b44b-719d7b583256")
    @kb_payment_id = java.util.UUID.fromString("bf5c926e-3d9c-470e-b34b-719d7b58323a")
    @kb_payment_method_id = java.util.UUID.fromString("bf5c926e-3d9c-470e-b34b-719d7b58323a")
    @payment_method_plugin = nil
    @amount = java.math.BigDecimal.new("50")
    @currency = Java::com.ning.billing.catalog.api.Currency::USD
  end

  before(:each) do
    @jpayment.delegate_plugin.send(:clear_exception_on_next_calls)
  end

  it "should_test_charge_ok" do
    output = @jpayment.process_payment(@kb_account_id, @kb_payment_id, @kb_payment_method_id, @amount, @currency)
    output.amount.should be_an_instance_of java.math.BigDecimal
    output.amount.to_s.should == "50.00";
    output.status.should be_an_instance_of Java::com.ning.billing.payment.plugin.api.PaymentPluginStatus
    output.status.to_s.should == "PROCESSED"
  end

  it "should_test_charge_exception" do
    @jpayment.delegate_plugin.send(:raise_exception_on_next_calls)
    lambda { @jpayment.process_payment(@kb_account_id, @kb_payment_id, @kb_payment_method_id, @amount, @currency) }.should raise_error Java::com.ning.billing.payment.plugin.api.PaymentPluginApiException
  end

  it "should_test_get_payment_info_ok" do
    output = @jpayment.get_payment_info(@kb_account_id, @kb_payment_method_id)
    output.amount.should be_an_instance_of java.math.BigDecimal
    output.amount.to_s.should == "0.00";
    output.status.should be_an_instance_of Java::com.ning.billing.payment.plugin.api.PaymentPluginStatus
    output.status.to_s.should == "PROCESSED"
  end

  it "should_test_get_payment_info_exception" do
    @jpayment.delegate_plugin.send(:raise_exception_on_next_calls)
    lambda { @jpayment.get_payment_info(@kb_account_id, @kb_payment_method_id) }.should raise_error Java::com.ning.billing.payment.plugin.api.PaymentPluginApiException
  end

  it "should_test_refund_ok" do
    output = @jpayment.process_refund(@kb_account_id, @kb_payment_method_id, @amount, @currency)
    output.amount.should be_an_instance_of java.math.BigDecimal
    output.amount.to_s.should == "50.00";
    output.status.should be_an_instance_of Java::com.ning.billing.payment.plugin.api.RefundPluginStatus
    output.status.to_s.should == "PROCESSED"
  end

  it "should_test_refund_exception" do
    @jpayment.delegate_plugin.send(:raise_exception_on_next_calls)
    lambda { @jpayment.process_refund(@kb_account_id, @kb_payment_method_id, @amount, @currency) }.should raise_error Java::com.ning.billing.payment.plugin.api.PaymentPluginApiException
  end

  it "should_test_add_payment_method_ok" do
    @jpayment.add_payment_method(@kb_account_id, @kb_payment_method_id, @payment_method_plugin, java.lang.Boolean.new("true"))
  end

  it "should_test_add_payment_method_exception" do
    @jpayment.delegate_plugin.send(:raise_exception_on_next_calls)
    lambda { @jpayment.add_payment_method(@kb_account_id, @kb_payment_method_id, @payment_method_plugin, true) }.should raise_error Java::com.ning.billing.payment.plugin.api.PaymentPluginApiException
  end

  it "should_test_delete_payment_method_ok" do
    @jpayment.delete_payment_method(@kb_account_id, @kb_payment_method_id)
  end

  it "should_test_delete_payment_method_exception" do
    @jpayment.delegate_plugin.send(:raise_exception_on_next_calls)
    lambda { @jpayment.delete_payment_method(@kb_account_id, @kb_payment_method_id) }.should raise_error Java::com.ning.billing.payment.plugin.api.PaymentPluginApiException
  end

  it "should_test_get_payment_method_detail_ok" do
    output = @jpayment.get_payment_method_detail(@kb_account_id, @kb_payment_method_id)
    output.external_payment_method_id.should be_an_instance_of java.lang.String
    output.external_payment_method_id.should == "foo"
  end

  it "should_test_get_payment_method_detail_exception" do
    @jpayment.delegate_plugin.send(:raise_exception_on_next_calls)
    lambda { @jpayment.get_payment_method_detail(@kb_account_id, @kb_payment_method_id) }.should raise_error Java::com.ning.billing.payment.plugin.api.PaymentPluginApiException
  end

  it "should_test_set_default_payment_method_ok" do
    @jpayment.set_default_payment_method(@kb_account_id, @kb_payment_method_id)
  end

  it "should_test_set_default_payment_method_exception" do
    @jpayment.delegate_plugin.send(:raise_exception_on_next_calls)
    lambda { @jpayment.set_default_payment_method(@kb_account_id, @kb_payment_method_id) }.should raise_error Java::com.ning.billing.payment.plugin.api.PaymentPluginApiException
  end

  it "should_get_payment_methods_ok" do
    output = @jpayment.get_payment_methods(@kb_account_id, java.lang.Boolean.new("true"))

    output.should be_an_instance_of java.util.ArrayList
    output.size.should == 1

    current_payment_method = output.get(0)
    current_payment_method.account_id.to_s.should == @kb_account_id.to_s
  end

  it "should_get_payment_methods_exception" do
    @jpayment.delegate_plugin.send(:raise_exception_on_next_calls)
    lambda { @jpayment.get_payment_methods(@kb_account_id, true) }.should raise_error Java::com.ning.billing.payment.plugin.api.PaymentPluginApiException
  end

  it "should_test_reset_payment_methods_ok" do
    @jpayment.reset_payment_methods(@kb_account_id, java.util.ArrayList.new)
  end

  it "should_test_reset_payment_methods_exception" do
    @jpayment.delegate_plugin.send(:raise_exception_on_next_calls)
    lambda { @jpayment.reset_payment_methods(@kb_account_id, java.util.ArrayList.new) }.should raise_error Java::com.ning.billing.payment.plugin.api.PaymentPluginApiException
  end
end
