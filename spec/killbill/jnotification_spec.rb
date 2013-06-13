require 'spec_helper'

require 'killbill/jnotification'

describe Killbill::Plugin::JNotification do

  before(:all) do
    logger = ::Logger.new(STDOUT)

    puts "**************************************************  1 ************************************"
    @jnotification =  Killbill::Plugin::JNotification.new("Killbill::Plugin::NotificationTest", { "logger" => logger })
    puts "**************************************************  2 ************************************"

  end


  it "should_test_on_event_ok" do

    puts "**************************************************  3 ************************************"

    object_type = Java::com.ning.billing.ObjectType::INVOICE
    event_type = Java::com.ning.billing.beatrix.bus.api.ExtBusEventType::INVOICE_CREATION
    uuid = java.util.UUID.random_uuid

    puts "**************************************************  4 ************************************"

    event = Java::com.ning.billing.mock.api.MockExtBusEvent.new(event_type, object_type, uuid, uuid, uuid)

    puts "**************************************************  5 ************************************"

    @jnotification.on_event(event)
    @jnotification.on_event(event)
    @jnotification.on_event(event)

    puts "**************************************************  6 ************************************"

    @jnotification.delegate_plugin.counter.should == 3
  end
end
