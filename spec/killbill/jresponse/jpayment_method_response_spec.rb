require 'spec_helper'
require 'date'

require 'killbill/response/payment_status'
require 'killbill/response/payment_method_response'

require 'killbill/jresponse/jpayment_method_response'


describe Killbill::Plugin::JPaymentMethodResponse do

    it "should_test_jpayment_method_response" do

      prop1 = Killbill::Plugin::PaymentMethodProperty.new('key1', 'value1', true)
      prop2 = Killbill::Plugin::PaymentMethodProperty.new('key2', 'value2', false)
      props  = []
      props << prop1
      props << prop2

      external_payment_method_id = "935e9aba-0031-4911-a137-aad7dd9a75b9"
      is_default = true
      input =  Killbill::Plugin::PaymentMethodResponse.new(external_payment_method_id, is_default, props)
      output = Killbill::Plugin::JPaymentMethodResponse.new(input)

      output.get_external_payment_method_id.should be_an_instance_of java.lang.String
      output.get_external_payment_method_id.to_s.should == external_payment_method_id

      output.is_default_payment_method.should be_an_instance_of java.lang.Boolean
      output.is_default_payment_method.to_s.should == is_default.to_s

      output.get_properties.should be_an_instance_of java.util.ArrayList


      output.get_properties.each_with_index do |p, i|
=begin
        p.get_key.should be_an_instance_of  java.lang.String
        p.get_value.should be_an_instance_of string #  java.lang.Object
        p.is_updateable be_an_instance_of TrueClass # java.lang.Boolean
=end
        if i == 0
          p.get_key.should == 'key1'
          p.get_value.to_s.should == 'value1'
          p.is_updatable.to_s.should == 'true'
        else
          p.get_key.should == 'key2'
          p.get_value.to_s.should == 'value2'
          p.is_updatable.to_s.should == 'false'
        end
      end

    end

end
