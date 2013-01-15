require 'spec_helper'

class DummyPaymentPlugin < Killbill::Plugin::Payment
end

describe Killbill::Plugin::Payment do
  before(:each) do
    @external_account_key = SecureRandom.uuid
    @killbill_payment_id = SecureRandom.uuid
    @amount_in_cents = rand(100000)

    @payment_method = Hash.new(:credit_card => SecureRandom.uuid)
    @external_payment_method_id = SecureRandom.uuid

    @killbill_account = Hash.new(:name => SecureRandom.uuid)

    @plugin = DummyPaymentPlugin.new
  end

  it "should raise exceptions for unsupported operations" do
    lambda { @plugin.charge(@external_account_key, @killbill_payment_id, @amount_in_cents) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.refund(@external_account_key, @killbill_payment_id, @amount_in_cents) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.get_payment_info(@killbill_payment_id) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.add_payment_method(@external_account_key, @payment_method) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.delete_payment_method(@external_account_key, @external_payment_method_id) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.update_payment_method(@external_account_key, @payment_method) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.set_default_payment_method(@external_account_key, @payment_method) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
    lambda { @plugin.create_account(@killbill_account) }.should raise_error Killbill::Plugin::Payment::OperationUnsupportedByGatewayError
  end
end
