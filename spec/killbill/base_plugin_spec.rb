require 'spec_helper'

class LifecycleNotificationPlugin < Killbill::Plugin::PluginBase
  attr_accessor :lifecycled

  def start_plugin
    @lifecycled = true
    super
  end

  def stop_plugin
    @lifecycled = true
    super
  end
end

describe Killbill::Plugin::PluginBase do
  it "should be able to add custom code in the startup/shutdown sequence" do
    plugin = LifecycleNotificationPlugin.new

    plugin.lifecycled = false
    plugin.lifecycled.should be_false
    plugin.active.should be_false

    plugin.start_plugin
    plugin.lifecycled.should be_true
    plugin.active.should be_true

    plugin.lifecycled = false
    plugin.lifecycled.should be_false
    plugin.active.should be_true

    plugin.stop_plugin
    plugin.lifecycled.should be_true
    plugin.active.should be_false
  end
end
