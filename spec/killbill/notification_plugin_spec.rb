require 'spec_helper'

class DummyNotificationPlugin < Killbill::Plugin::Notification
end

class HoarderNotificationPlugin < Killbill::Plugin::Notification
  attr_reader :events

  def start_plugin
    @events = []
    super
  end

  def on_event(event)
    @events << event
  end

  def stop_plugin
    super
    @events = []
  end
end

describe Killbill::Plugin::Notification do
  before(:each) do
    @event = Hash.new(:account_id => SecureRandom.uuid)
  end

  it "should not raise exceptions by default" do
    plugin = DummyNotificationPlugin.new
    lambda { plugin.on_event(@event) }.should_not raise_error
  end

  it "should be able to receive all events" do
    plugin = HoarderNotificationPlugin.new

    plugin.start_plugin
    plugin.events.size.should == 0

    (1..100).each do |i|
      plugin.on_event(@event)
      plugin.events.size.should == i
      plugin.events[-1].should == @event
    end

    plugin.stop_plugin
    plugin.events.size.should == 0
  end
end
