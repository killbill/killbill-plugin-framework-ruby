require 'spec_helper'
require 'date'

require 'killbill/response/payment_status'
require 'killbill/response/payment_response'
require 'killbill/response/refund_response'

require 'killbill/jresponse/jconverter'

describe Killbill::Plugin::JConverter do

    it "should_test_uuid_converter" do
      input = "bf5c926e-3d9c-470e-b34b-0719d7b58323"
      output = Killbill::Plugin::JConverter.to_uuid(input)
      output.should be_an_instance_of java.util.UUID
      output.to_s.should == input
    end

    it "should_test_joda_date_time_converter" do
      input_str = '2013-03-11T16:05:11-07:00'
      expected_output_str = '2013-03-11T16:05:11.000-07:00'
      input = org.joda.time.DateTime.parse(input_str)
      output = Killbill::Plugin::JConverter.to_joda_date_time(input)
      output.should be_an_instance_of org.joda.time.DateTime
      output.to_s.should ==  expected_output_str
    end

    it "should_test_to_string_converter" do
      input = "great it works"
      output = Killbill::Plugin::JConverter.to_string(input)
      output.should be_an_instance_of java.lang.String
      output.should == input
    end

    it "should_test_payment_plugin_status_success_converter" do
      input = Killbill::Plugin::PaymentStatus::SUCCESS
      output = Killbill::Plugin::JConverter.to_payment_plugin_status(input)
      output.should be_an_instance_of Java::com.ning.billing.payment.plugin.api.PaymentInfoPlugin::PaymentPluginStatus
      output.should == Java::com.ning.billing.payment.plugin.api.PaymentInfoPlugin::PaymentPluginStatus::PROCESSED
    end

    it "should_test_payment_plugin_status_failed_converter" do
      input = Killbill::Plugin::PaymentStatus::ERROR
      output = Killbill::Plugin::JConverter.to_payment_plugin_status(input)
      output.should be_an_instance_of Java::com.ning.billing.payment.plugin.api.PaymentInfoPlugin::PaymentPluginStatus
      output.should == Java::com.ning.billing.payment.plugin.api.PaymentInfoPlugin::PaymentPluginStatus::ERROR
    end

    it "should_test_payment_plugin_status_undefined_converter" do
      input = Killbill::Plugin::PaymentStatus::UNDEFINED
      output = Killbill::Plugin::JConverter.to_payment_plugin_status(input)
      output.should be_an_instance_of Java::com.ning.billing.payment.plugin.api.PaymentInfoPlugin::PaymentPluginStatus
      output.should == Java::com.ning.billing.payment.plugin.api.PaymentInfoPlugin::PaymentPluginStatus::UNDEFINED
    end

    it "should_test_big_decimal_converter" do
      {
        nil => '0',
        1 => '0.01',
        0 => '0',
        -1 => '-0.01',
        12376 => '12.376',
        -532 => '-5.32'
      }.each do |input,output|
        output = Killbill::Plugin::JConverter.to_big_decimal(input)
        output.should be_an_instance_of java.math.BigDecimal
        output.to_s.should == output.to_s
      end
    end

    it "should_test_boolean_true_converter" do
      input = true
      output = Killbill::Plugin::JConverter.to_boolean(input)
      output.should be_an_instance_of java.lang.Boolean
      output.to_s == input.to_s
    end

    it "should_test_boolean_false_converter" do
      input = nil
      output = Killbill::Plugin::JConverter.to_boolean(input)
      output.should be_an_instance_of java.lang.Boolean
      output.to_s == "false"
    end

end
