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
  it 'should be able to register Killbill API instances' do
    plugin = Killbill::Plugin::PluginBase.new(:account_user_api => MockAccountUserApi.new)

    plugin.account_user_api.get_accounts(nil).size.should == 0
    # Existing API, present
    lambda { plugin.account_user_api.do_foo('with my bar') }.should_not raise_error Killbill::Plugin::PluginBase::APINotAvailableError
    # Existing API, absent
    lambda { plugin.payment_api.do_foo('with my bar') }.should raise_error Killbill::Plugin::PluginBase::APINotAvailableError
    # Non-existing API
    lambda { plugin.foobar_user_api.do_foo('with my bar') }.should raise_error Killbill::Plugin::PluginBase::APINotAvailableError
  end

  it 'should be able to add custom code in the startup/shutdown sequence' do
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
