require 'spec_helper'

describe Killbill::Plugin::ActiveMerchant do

  let(:logger) do
    logger       = Logger.new(STDOUT)
    logger.level = Logger::INFO
    logger
  end

  let(:call_context) do
    call_context           = Killbill::Plugin::Model::CallContext.new
    call_context.tenant_id = '00001011-a022-b033-0055-aa0000000066'
    call_context.to_ruby(call_context)
  end

  it 'should support multi-tenancy configurations' do
    do_initialize!(<<-eos)
  :login: admin
  :password: password
  :test: true
    eos

    do_common_checks

    gw = ::Killbill::Plugin::ActiveMerchant.gateways(call_context.tenant_id)
    gw.size.should == 1
    gw[:default][:login].should == 'admin2'
    gw[:default][:password].should == 'password2'

    ::Killbill::Plugin::ActiveMerchant.config_key_name.should == :KEY
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

  it 'should honor ActiveMerchant configuration options' do
    do_initialize!
    do_common_checks
    verify_active_merchant_config

    do_initialize!(<<-eos)
  :retry_safe: true
  :open_timeout: 12
  :ssl_version: 5
  :ssl_strict: false
    eos
    do_common_checks
    verify_active_merchant_config(:retry_safe => true, :open_timeout => 12, :ssl_version => 5, :ssl_strict => false)
  end

  it 'sets up false pool with jndi database configuration' do
    db_config = { :adapter => 'mysql2', :jndi => 'jdbc/MyDB', :pool => false }

    ActiveRecord::Base.should_receive(:establish_connection).with(db_config).once
    do_initialize!({ :test => true }, db_config)

    pool_class = ActiveRecord::Base.connection_handler.connection_pool_class
    expect( pool_class ).to be ActiveRecord::Bogacs::FalsePool
  end

  after do
    if ::ActiveRecord::ConnectionAdapters::ConnectionHandler.respond_to?(:connection_pool_class=)
      pool_class = ::ActiveRecord::ConnectionAdapters::ConnectionPool # restore if Bogacs loaded
      ::ActiveRecord::ConnectionAdapters::ConnectionHandler.connection_pool_class = pool_class
    end
  end

  private

  def do_common_checks
    ::Killbill::Plugin::ActiveMerchant.config.should_not be_nil
    ::Killbill::Plugin::ActiveMerchant.currency_conversions.should be_nil
    ::Killbill::Plugin::ActiveMerchant.initialized.should be_true
    ::Killbill::Plugin::ActiveMerchant.kb_apis.should_not be_nil
    ::Killbill::Plugin::ActiveMerchant.logger.should == logger
  end

  def verify_active_merchant_config(config = {})
    ::ActiveMerchant::Billing::Gateway.open_timeout.should == (config.has_key?(:open_timeout) ? config[:open_timeout] : 60)
    ::ActiveMerchant::Billing::Gateway.read_timeout.should == (config.has_key?(:read_timeout) ? config[:read_timeout] : 60)
    ::ActiveMerchant::Billing::Gateway.retry_safe.should == (config.has_key?(:retry_safe) ? config[:retry_safe] : false)
    ::ActiveMerchant::Billing::Gateway.ssl_strict.should == (config.has_key?(:ssl_strict) ? config[:ssl_strict] : true)
    ::ActiveMerchant::Billing::Gateway.ssl_version.should == (config.has_key?(:ssl_version) ? config[:ssl_version] : nil)
    ::ActiveMerchant::Billing::Gateway.max_retries.should == (config.has_key?(:max_retries) ? config[:max_retries] : 3)
    ::ActiveMerchant::Billing::Gateway.proxy_address.should == (config.has_key?(:proxy_address) ? config[:proxy_address] : nil)
    ::ActiveMerchant::Billing::Gateway.proxy_port.should == (config.has_key?(:proxy_port) ? config[:proxy_port] : nil)
  end

  def do_initialize!(extra_config = '', db_config = database_config)
    extra_config_yaml = ''; db_config_yaml = ''

    [[extra_config, extra_config_yaml],
     [db_config, db_config_yaml]].each do |config, config_yaml|
      if config.is_a?(String)
        config_yaml.replace(config)
      else
        config.to_yaml.sub("---\n", '').each_line { |line| config_yaml << "  #{line}" } # indent
      end
    end

    Dir.mktmpdir do |dir|
      File.open(path = File.join(dir, 'test.yml'), 'w+') do |file|
        file.write(":test:\n#{extra_config_yaml}:database:\n#{db_config_yaml}")
        file.close

        per_tenant_config =<<-oes
:test:
  :login: admin2
  :password: password2
:database:
  :adapter: 'sqlite3'
  :database: 'test.db'
        oes
        @tenant_api = ::Killbill::Plugin::ActiveMerchant::RSpec::FakeJavaTenantUserApi.new({call_context.tenant_id => per_tenant_config})
        svcs = {:tenant_user_api => @tenant_api}

        ::Killbill::Plugin::ActiveMerchant.initialize! Proc.new { |config| config },
                                                       :test,
                                                       logger,
                                                       :KEY,
                                                       file.path,
                                                       ::Killbill::Plugin::KillbillApi.new('test', svcs)
      end
    end
  end
end
