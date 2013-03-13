require 'spec_helper'

require 'killbill/jpayment'

describe Killbill::Plugin::JPayment do

=begin
  before(:all) do
    @jpayment = JPayment.new("Killbill::Plugin::PaymentTest")
    @kb_payment_id = SecureRandom.uuid
    @kb_payment_method_id = SecureRandom.uuid
    @amount_in_cents = 5000
   end

   it "should_test_charge" do
     output = @jpayment.charge(@kb_payment_id, @kb_payment_method_id, @amount_in_cents)

     output.should be_an_instance_of Java::com.ning.billing.payment.plugin.api.PaymentInfoPlugin

     output.get_amount.should be_an_instance_of java.math.BigDecimal
     output.get_amount.to_s.should == @amount_in_cents.to_s;

     output.get_status.should be_an_instance_of Java::com.ning.billing.payment.plugin.api.PaymentInfoPlugin::PaymentPluginStatus
     output.get_status.to_s.should == "PROCESSED"
   end
=end
end