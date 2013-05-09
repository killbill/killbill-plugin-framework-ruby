require 'spec_helper'
require 'date'

require 'killbill/response/event'
require 'killbill/jresponse/jevent'


describe Killbill::Plugin::JEvent do

    it "should_test_jevent" do
      object_type = Java::com.ning.billing.ObjectType::INVOICE
      event_type = Java::com.ning.billing.beatrix.bus.api.ExtBusEventType::INVOICE_CREATION
      uuid = java.util.UUID.random_uuid

      input = Killbill::Plugin::JEvent.new(event_type, object_type, uuid, uuid, uuid)
      #input.should be_an_instance_of Java::com.ning.billing.beatrix.bus.api.ExtBusEvent
    end
end
