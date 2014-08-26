require 'spec_helper'

class DummyPaymentPlugin < Killbill::Plugin::Payment
end

describe Killbill::Plugin::Payment do
  before(:each) do
    @kb_account_id             = SecureRandom.uuid
    @kb_payment_id             = SecureRandom.uuid
    @kb_payment_transaction_id = SecureRandom.uuid
    @amount_in_cents           = rand(100000)
    @currency                  = 'USD'
    @call_context              = Killbill::Plugin::Model::CallContext.new

    @kb_payment_method_id = SecureRandom.uuid

    @search_key = SecureRandom.uuid
    @offset     = 0
    @limit      = 100

    @properties           = [::Killbill::Plugin::Model::PluginProperty.new]
    @payment_method_props = Hash.new
    @payment_methods      = Hash.new
    @killbill_account     = Hash.new(:name => SecureRandom.uuid)

    @plugin = DummyPaymentPlugin.new
  end

  it "should raise exceptions for unsupported operations" do
    lambda { @plugin.authorize_payment(@kb_account_id, @kb_payment_id, @kb_payment_transaction_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.capture_payment(@kb_account_id, @kb_payment_id, @kb_payment_transaction_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.purchase_payment(@kb_account_id, @kb_payment_id, @kb_payment_transaction_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.void_payment(@kb_account_id, @kb_payment_id, @kb_payment_transaction_id, @kb_payment_method_id, @properties, @call_context) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.credit_payment(@kb_account_id, @kb_payment_id, @kb_payment_transaction_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.refund_payment(@kb_account_id, @kb_payment_id, @kb_payment_transaction_id, @kb_payment_method_id, @amount_in_cents, @currency, @properties, @call_context) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.get_payment_info(@kb_account_id, @kb_payment_id, @properties, @call_context) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.search_payments(@search_key, @offset, @limit, @properties, @call_context) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.add_payment_method(@kb_account_id, @kb_payment_method_id, @payment_method_props, true, @properties, @call_context) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.delete_payment_method(@kb_account_id, @kb_payment_method_id, @properties, @call_context) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.get_payment_method_detail(@kb_account_id, @kb_payment_method_id, @properties, @call_context) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.set_default_payment_method(@kb_account_id, @kb_payment_method_id, @properties, @call_context) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.get_payment_methods(@kb_account_id, true, @properties, @call_context) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.search_payment_methods(@search_key, @offset, @limit, @properties, @call_context) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.reset_payment_methods(@kb_account_id, @payment_methods, @properties, @call_context) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.build_form_descriptor(@kb_account_id, [], @properties, @call_context) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.process_notification("{ 'key' => 'value' }", @properties, @call_context) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
  end
end
