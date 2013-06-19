require 'spec_helper'

require 'killbill/jnotification'

describe Killbill::Plugin::JNotification do

  before(:all) do
    logger = ::Logger.new(STDOUT)
    @jnotification =  Killbill::Plugin::JNotification.new("Killbill::Plugin::NotificationTest", { "logger" => logger })
  end


  it "should_test_on_event_ok" do

    object_type = Java::com.ning.billing.ObjectType::INVOICE
    event_type = Java::com.ning.billing.notification.plugin.api.ExtBusEventType::INVOICE_CREATION
    uuid = java.util.UUID.random_uuid

    event = Java::com.ning.billing.mock.api.MockExtBusEvent.new(event_type, object_type, uuid, uuid, uuid)
    @jnotification.on_event(event)
    @jnotification.on_event(event)
    @jnotification.on_event(event)
    @jnotification.delegate_plugin.counter.should == 3
  end
end
