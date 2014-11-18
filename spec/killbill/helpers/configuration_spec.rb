require 'spec_helper'

describe Killbill::Plugin::ActiveMerchant do

  before(:all) do
    @logger       = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  it 'should support a configuration for a single gateway' do
    do_initialize!(<<-eos)
  :login: admin
  :password: password
  :test: true
    eos

    do_common_checks

    gw = ::Killbill::Plugin::ActiveMerchant.gateways
    gw.size.should == 1
    gw[:default][:login].should == 'admin'
    gw[:default][:password].should == 'password'
  end

  it 'should support a configuration for multiple gateways with a default' do
    do_initialize!(<<-eos)
  - :account_id: :credentials_1
    :test: true
    :login: admin_1
    :password: password_1
  - :account_id: :credentials_2
    :test: true
    :login: admin_2
    :password: password_2
  - :account_id: :default
    :test: true
    :login: admin_3
    :password: password_3
  - :account_id: :credentials_4
    :test: true
    :login: admin_4
    :password: password_4
    eos

    do_common_checks

    gw = ::Killbill::Plugin::ActiveMerchant.gateways
    gw.size.should == 4
    [1, 2, 4].each do |i|
      gw["credentials_#{i}".to_sym][:login].should == "admin_#{i}"
      gw["credentials_#{i}".to_sym][:password].should == "password_#{i}"
    end
    gw[:default][:login].should == 'admin_3'
    gw[:default][:password].should == 'password_3'
  end

  it 'should support a configuration for multiple gateways without a default' do
    do_initialize!(<<-eos)
  - :account_id: :credentials_1
    :login: admin_1
    :password: password_1
  - :account_id: :credentials_2
    :login: admin_2
    :password: password_2
  - :account_id: :credentials_3
    :login: admin_3
    :password: password_3
  - :account_id: :credentials_4
    :login: admin_4
    :password: password_4
    eos

    do_common_checks

    gw = ::Killbill::Plugin::ActiveMerchant.gateways
    gw.size.should == 5
    [1, 2, 3, 4].each do |i|
      gw["credentials_#{i}".to_sym][:login].should == "admin_#{i}"
      gw["credentials_#{i}".to_sym][:password].should == "password_#{i}"
    end
    gw[:default][:login].should == 'admin_1'
    gw[:default][:password].should == 'password_1'
  end

  private

  def do_common_checks
    ::Killbill::Plugin::ActiveMerchant.config.should_not be_nil
    ::Killbill::Plugin::ActiveMerchant.currency_conversions.should be_nil
    ::Killbill::Plugin::ActiveMerchant.initialized.should be_true
    ::Killbill::Plugin::ActiveMerchant.kb_apis.should_not be_nil
    ::Killbill::Plugin::ActiveMerchant.logger.should == @logger
  end

  def do_initialize!(extra_config='')
    db_config = ''
    database_config.to_yaml.sub("---\n", '').
      each_line { |line| db_config << "  #{line}" } # indent

    Dir.mktmpdir do |dir|
      file = File.new(File.join(dir, 'test.yml'), 'w+')
      file.write(<<-eos)
:test:
#{extra_config}
# As defined by spec_helper.rb
:database:
#{db_config}
      eos
      file.close

      ::Killbill::Plugin::ActiveMerchant.initialize! Proc.new { |config| config },
                                                     :test,
                                                     @logger,
                                                     file.path,
                                                     ::Killbill::Plugin::KillbillApi.new('test', {})
    end
  end
end
