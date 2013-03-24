require 'spec_helper'
require 'date'

require 'killbill/response/payment_status'
require 'killbill/response/refund_response'

require 'killbill/jresponse/jrefund_response'


describe Killbill::Plugin::JRefundResponse do

    it "should_test_jrefund_response" do

      amount = 12352
      created_date = DateTime.new
      effective_date = DateTime.new
      status = Killbill::Plugin::PaymentStatus::SUCCESS
      gateway_error = "whatever"
      gateway_error_code = nil

      input = Killbill::Plugin::RefundResponse.new(amount, created_date, effective_date, status, gateway_error, gateway_error_code)
      output = Killbill::Plugin::JRefundResponse.new(input)
      output.get_amount.should be_an_instance_of java.math.BigDecimal
      output.get_amount.to_s.should == '123.52';

      output.get_created_date.should be_an_instance_of org.joda.time.DateTime
      #output.get_created_date.get_millis == created_date.to_s;

      output.get_effective_date.should be_an_instance_of org.joda.time.DateTime
      #output.get_effective_date.to_s.should == effective_date.to_s;

      output.get_status.should be_an_instance_of Java::com.ning.billing.payment.plugin.api.RefundInfoPlugin::RefundPluginStatus
      output.get_status.to_s.should == "PROCESSED"

      output.get_gateway_error.should be_an_instance_of java.lang.String
      output.get_gateway_error.to_s.should == gateway_error

      output.get_gateway_error_code.should be_nil

    end
end