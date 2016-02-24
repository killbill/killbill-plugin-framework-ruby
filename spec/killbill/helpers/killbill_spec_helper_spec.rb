require 'spec_helper'

describe Killbill::Plugin::ActiveMerchant::RSpec do
  include Killbill::Plugin::ActiveMerchant::RSpec

  it 'should build payment method properties' do
    overridden_city = SecureRandom.uuid

    props1 = build_pm_properties
    props2 = build_pm_properties(nil, {:city => overridden_city})
    props3 = build_pm_properties(nil, {:city => overridden_city, :foo => :bar})

    props1.size.should == props2.size
    props3.size.should == props1.size + 1

    city1 = props1.find { |p| p.key == 'city' }
    city2 = props2.find { |p| p.key == 'city' }
    city3 = props3.find { |p| p.key == 'city' }
    city1.value.should_not == city2.value
    city2.value.should == city3.value

    (props3.find { |p| p.key == :foo }).value.should == :bar
  end

  it 'should build test contexts in Ruby' do
    call_context = build_call_context('12345')
    call_context.tenant_id.should == '12345'
    call_context.created_date.should be_nil
  end
end
