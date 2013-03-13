require 'spec_helper'
require 'date'

require 'killbill/response/payment_status'
require 'killbill/response/payment_method_response_internal'

require 'killbill/jresponse/jpayment_method_response_internal'


describe Killbill::Plugin::JPaymentMethodResponseInternal do

    it "should_test_jpayment_method_response_internal" do

      kb_account_id = "935e9aba-0031-4911-a137-aad7dd9a75b9"
      kb_payment_method_id = "37462cc7-834b-48c6-8fd6-e8e038f4c41d"
      is_default = true
      external_payment_method_id = "foo"

      input = Killbill::Plugin::PaymentMethodResponseInternal.new(kb_account_id, kb_payment_method_id, is_default, external_payment_method_id)
      output = Killbill::Plugin::JPaymentMethodResponseInternal.new(input)

      output.get_account_id.should be_an_instance_of java.util.UUID
      output.get_account_id.to_s.should == kb_account_id

      output.get_payment_method_id.should be_an_instance_of java.util.UUID
      output.get_payment_method_id.to_s.should == kb_payment_method_id

      output.is_default.should be_an_instance_of java.lang.Boolean
      output.is_default.to_s.should == is_default.to_s

      output.get_external_payment_method_id.should be_an_instance_of java.lang.String
      output.get_external_payment_method_id.should == external_payment_method_id
    end
end