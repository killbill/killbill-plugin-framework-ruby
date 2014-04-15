require 'spec_helper'

ActiveMerchant::Billing::Base.mode = :test

class FakeJavaUserAccountApi
  attr_accessor :accounts

  def initialize
    @accounts = []
  end

  def get_account_by_id(id, context)
    @accounts.find { |account| account.id == id.to_s }
  end

  def get_account_by_key(external_key, context)
    @accounts.find { |account| account.external_key == external_key.to_s }
  end
end

describe Killbill::<%= class_name %>::PaymentPlugin do
  before(:each) do
    @plugin = Killbill::<%= class_name %>::PaymentPlugin.new

    @account_api = FakeJavaUserAccountApi.new
    svcs = {:account_user_api => @account_api}
    @plugin.kb_apis = Killbill::Plugin::KillbillApi.new('<%= identifier %>', svcs)

    @plugin.logger = Logger.new(STDOUT)
    @plugin.logger.level = Logger::INFO
    @plugin.conf_dir = File.expand_path(File.dirname(__FILE__) + '../../../../')
    @plugin.start_plugin
  end

  after(:each) do
    @plugin.stop_plugin
  end

  it 'should be able to create and retrieve payment methods' do
  end

  it 'should be able to charge and refund' do
  end
end
