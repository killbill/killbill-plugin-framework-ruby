require 'spec_helper'

describe Killbill::Plugin::ActiveMerchant::Gateway do

  it 'should honor configuration options' do
    gateway_builder = Proc.new {}
    logger          = Logger.new(STDOUT)
    config          = {}

    verify_config

    ::Killbill::Plugin::ActiveMerchant::Gateway.wrap(gateway_builder, logger, config)
    verify_config(config)

    config1 = {:open_timeout => 12, :ssl_version => 5}
    ::Killbill::Plugin::ActiveMerchant::Gateway.wrap(gateway_builder, logger, config1)
    verify_config(config1)

    config2 = {:retry_safe => true, :ssl_strict => false, :max_retries => nil}
    ::Killbill::Plugin::ActiveMerchant::Gateway.wrap(gateway_builder, logger, config2)
    verify_config(config1.merge(config2).delete_if { |k, v| v.nil? })
  end

  private

  def verify_config(config = {})
    ::ActiveMerchant::Billing::Gateway.open_timeout.should == (config.has_key?(:open_timeout) ? config[:open_timeout] : 60)
    ::ActiveMerchant::Billing::Gateway.read_timeout.should == (config.has_key?(:read_timeout) ? config[:read_timeout] : 60)
    ::ActiveMerchant::Billing::Gateway.retry_safe.should == (config.has_key?(:retry_safe) ? config[:retry_safe] : false)
    ::ActiveMerchant::Billing::Gateway.ssl_strict.should == (config.has_key?(:ssl_strict) ? config[:ssl_strict] : true)
    ::ActiveMerchant::Billing::Gateway.ssl_version.should == (config.has_key?(:ssl_version) ? config[:ssl_version] : nil)
    ::ActiveMerchant::Billing::Gateway.max_retries.should == (config.has_key?(:max_retries) ? config[:max_retries] : 3)
    ::ActiveMerchant::Billing::Gateway.proxy_address.should == (config.has_key?(:proxy_address) ? config[:proxy_address] : nil)
    ::ActiveMerchant::Billing::Gateway.proxy_port.should == (config.has_key?(:proxy_port) ? config[:proxy_port] : nil)
  end
end
