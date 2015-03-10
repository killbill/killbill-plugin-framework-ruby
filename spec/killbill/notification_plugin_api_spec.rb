require 'spec_helper'


describe Killbill::Plugin::Api::NotificationPluginApi do

  before(:all) do
    logger = ::Logger.new(STDOUT)
    @notificationPluginApi =  Killbill::Plugin::Api::NotificationPluginApi.new("Killbill::Plugin::NotificationTest", { "logger" => logger, "root" => "/a/b/plugin_name/1.2.3" })
  end


  it "should_test_on_event_ok" do
    object_type = Java::org.killbill.billing.ObjectType::INVOICE
    event_type = Java::org.killbill.billing.notification.plugin.api.ExtBusEventType::INVOICE_CREATION
    uuid = java.util.UUID.random_uuid
    event = Java::org.killbill.billing.mock.api.MockExtBusEvent.new(event_type, object_type, uuid, uuid, uuid)
    @notificationPluginApi.on_event(event)
    @notificationPluginApi.on_event(event)
    @notificationPluginApi.on_event(event)
    @notificationPluginApi.delegate_plugin.counter.should == 3
  end
end
