require 'spec_helper'
require 'date'

require 'killbill/response/payment_method_response'
require 'killbill/response/payment_method_response_internal'
require 'killbill/response/payment_status'
require 'killbill/response/payment_response'
require 'killbill/response/refund_response'
require 'killbill/response/event'

require 'killbill/jresponse/jpayment_method_response'
require 'killbill/jresponse/jpayment_method_response_internal'
require 'killbill/jresponse/jevent'

require 'killbill/jconverter'

describe Killbill::Plugin::JConverter do

    it "should_test_uuid_converter" do
      input = "bf5c926e-3d9c-470e-b34b-0719d7b58323"
      output = Killbill::Plugin::JConverter.to_uuid(input)
      output.should be_an_instance_of java.util.UUID
      output.to_s.should == input
    end

    it "should_test_joda_date_time_converter" do
      input_str = '2013-03-11T16:05:11-07:00'
      expected_output_str = '2013-03-11T23:05:11.000Z'
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

    it "should_test_to_string_converter_from_non_string" do
      input = 12
      output = Killbill::Plugin::JConverter.to_string(input)
      output.should be_an_instance_of java.lang.String
      output.should == input.to_s
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

    it "should_test_uuid_from_converter" do
      input = java.util.UUID.random_uuid
      output = Killbill::Plugin::JConverter.from_uuid(input)
      output.should be_an_instance_of Killbill::Plugin::Gen::UUID
      output.to_s.should == input.to_s
    end


    it "should_test_boolean_from_nil_converter" do
      input = nil
      output = Killbill::Plugin::JConverter.from_boolean(input)
      output.should be_an_instance_of FalseClass
      output.to_s == "false"
    end

    it "should_test_boolean_from_false_converter" do
      input = java.lang.Boolean.new("false")
      output = Killbill::Plugin::JConverter.from_boolean(input)
      output.should be_an_instance_of FalseClass
      output.to_s == "false"
    end

    it "should_test_boolean_from_false2_converter" do
      input = java.lang.Boolean.new("false").boolean_value
      output = Killbill::Plugin::JConverter.from_boolean(input)
      output.should be_an_instance_of FalseClass
      output.to_s == "false"
    end


    it "should_test_boolean_from_true_converter" do
      input = java.lang.Boolean.new("true")
      output = Killbill::Plugin::JConverter.from_boolean(input)
      output.should be_an_instance_of TrueClass
      output.to_s == "true"
    end

    it "should_test_boolean_from_true2_converter" do
      input = java.lang.Boolean.new("true").boolean_value
      output = Killbill::Plugin::JConverter.from_boolean(input)
      output.should be_an_instance_of TrueClass
      output.to_s == "true"
    end


    it "should_test_joda_time_from_converter" do
      input = org.joda.time.DateTime.new(org.joda.time.DateTimeZone::UTC)
      input = input.minus_millis(input.millis_of_second)
      output = Killbill::Plugin::JConverter.from_joda_date_time(input)
      output.should be_an_instance_of DateTime

      input_match = Killbill::Plugin::JConverter.to_joda_date_time(output)
      input_match.to_s.should == input.to_s
    end

    it "should_test_payment_status_from_converter" do
      input = Java::com.ning.billing.payment.plugin.api.PaymentInfoPlugin::PaymentPluginStatus::PROCESSED
      output = Killbill::Plugin::JConverter.from_payment_plugin_status(input)
      output.should == Killbill::Plugin::PaymentStatus::SUCCESS
    end

    it "should_test_big_decimal_from_converter" do
      input = java.math.BigDecimal::TEN
      output = Killbill::Plugin::JConverter.from_big_decimal(input)
      output.should be_an_instance_of Fixnum
      output.to_s.should == "1000"
    end

    it "should_test_payment_method_plugin_from_converter" do
      prop = Killbill::Plugin::PaymentMethodProperty.new("key", "value", true)
      payment_method_response = Killbill::Plugin::PaymentMethodResponse.new("external_payment_method_id", true, [prop])
      input = Killbill::Plugin::JPaymentMethodResponse.new(payment_method_response)
      output = Killbill::Plugin::JConverter.from_payment_method_plugin(input)

      output.should be_an_instance_of Killbill::Plugin::PaymentMethodResponse

      output.external_payment_method_id.should be_an_instance_of String
      output.external_payment_method_id.should == payment_method_response.external_payment_method_id

      output.is_default.should be_an_instance_of TrueClass
      output.is_default.should == payment_method_response.is_default

      output.properties.should be_an_instance_of Array
      output.properties.size.should == 1

      output_prop = output.properties[0]
      output_prop.should be_an_instance_of Killbill::Plugin::PaymentMethodProperty

      output_prop.key.should be_an_instance_of String
      output_prop.key.should == prop.key

      output_prop.value.should be_an_instance_of String
      output_prop.value.should == prop.value

      output_prop.is_updatable.should be_an_instance_of TrueClass
      output_prop.is_updatable.should == prop.is_updatable
    end

    it "should_test_payment_method_info_plugin__from_converter" do

      payment_method_info = Killbill::Plugin::PaymentMethodResponseInternal.new("bf5c926e-3d9c-470e-b34b-0719d7b58323", "ca5c926e-3d9c-470e-b34b-0719d7b58312", false, "external_payment_method_id")
      input = Killbill::Plugin::JPaymentMethodResponseInternal.new(payment_method_info)
      output = Killbill::Plugin::JConverter.from_payment_method_info_plugin(input)

      output.should be_an_instance_of Killbill::Plugin::PaymentMethodResponseInternal

      output.kb_account_id.should be_an_instance_of Killbill::Plugin::Gen::UUID
      output.kb_account_id.to_s.should == payment_method_info.kb_account_id.to_s

      output.kb_payment_method_id.should be_an_instance_of Killbill::Plugin::Gen::UUID
      output.kb_payment_method_id.to_s.should == payment_method_info.kb_payment_method_id.to_s

      output.is_default.should be_an_instance_of FalseClass
      output.is_default.should == payment_method_info.is_default

      output.external_payment_method_id.should be_an_instance_of String
      output.external_payment_method_id.should == payment_method_info.external_payment_method_id
     end

     it "should_test_ext_bus_event__from_converter" do

       object_type = Java::com.ning.billing.ObjectType::INVOICE
       event_type = Java::com.ning.billing.beatrix.bus.api.ExtBusEventType::INVOICE_CREATION
       uuid = java.util.UUID.random_uuid

       input = Killbill::Plugin::JEvent.new(event_type, object_type, uuid, uuid, uuid)
       output = Killbill::Plugin::JConverter.from_ext_bus_event(input)

       output.should be_an_instance_of Killbill::Plugin::Event

       output.event_type.should be_an_instance_of String
       output.event_type.should == 'INVOICE_CREATION'

       output.object_type.should be_an_instance_of String
       output.object_type.should == 'INVOICE'

       output.object_id.should be_an_instance_of Killbill::Plugin::Gen::UUID
       output.object_id.to_s.should == Killbill::Plugin::JConverter.from_uuid(uuid).to_s

       output.account_id.should be_an_instance_of Killbill::Plugin::Gen::UUID
       output.account_id.to_s.should == Killbill::Plugin::JConverter.from_uuid(uuid).to_s

       output.tenant_id.should be_an_instance_of Killbill::Plugin::Gen::UUID
       output.tenant_id.to_s.should == Killbill::Plugin::JConverter.from_uuid(uuid).to_s

      end
end
