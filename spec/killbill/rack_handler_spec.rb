require 'spec_helper'
require 'logger'

describe Killbill::Plugin::RackHandler do
  it 'should be able to register Sinatra apps' do
    rack = Killbill::Plugin::RackHandler.instance
    rack.configured?.should be_false

    rack.configure(Logger.new(STDOUT), File.expand_path('../config_test.ru', __FILE__))
    rack.configured?.should be_true

    status, headers, body = rack.rack_service('/ping')
    status.should == 200
    body.join('').should == 'pong'
  end
end
