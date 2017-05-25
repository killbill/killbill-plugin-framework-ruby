require 'logger'
require 'pathname'
require 'thread_safe'

module Killbill
  module Plugin
    module ActiveMerchant

      mattr_reader :glob_config
      mattr_reader :glob_currency_conversions

      mattr_reader :initialized
      mattr_reader :kb_apis
      mattr_reader :gateway_name
      mattr_reader :gateway_builder
      # To be kept in sync with sinatra.rb
      mattr_reader :logger
      mattr_reader :config_key_name
      mattr_reader :per_tenant_config_cache

      class << self

        def initialize!(gateway_builder, gateway_name, logger, config_key_name, config_file, kb_apis)
          @@logger = logger
          @@kb_apis = kb_apis
          @@gateway_name = gateway_name
          @@gateway_builder = gateway_builder
          @@config_key_name = config_key_name
          @@per_tenant_config_cache = ThreadSafe::Cache.new
          @@per_tenant_gateways_cache = ThreadSafe::Cache.new

          initialize_from_global_config!(config_file)
        end

        def gateways(kb_tenant_id=nil)
          if @@per_tenant_gateways_cache[kb_tenant_id].nil?
            tenant_config = get_tenant_config(kb_tenant_id)
            @@per_tenant_gateways_cache[kb_tenant_id] = extract_gateway_config(tenant_config)
          end
          @@per_tenant_gateways_cache[kb_tenant_id]
        end

        def currency_conversions(kb_tenant_id=nil)
          tenant_config = get_tenant_config(kb_tenant_id)
          if tenant_config
            tenant_config[:currency_conversions]
          else
            @@glob_currency_conversions
          end
        end

        # To be kept in sync with sinatra.rb
        def config(kb_tenant_id=nil)
          @@glob_config.merge(get_tenant_config(kb_tenant_id) || {})
        end

        def converted_currency(currency, kb_tenant_id=nil)
          currency_sym = currency.to_s.upcase.to_sym
          tmp = currency_conversions(kb_tenant_id)
          tmp && tmp[currency_sym]
        end

        def invalidate_tenant_config!(kb_tenant_id)
          @@logger.info("Invalidate plugin key #{@@config_key_name}, tenant = #{kb_tenant_id}")
          @@per_tenant_config_cache[kb_tenant_id] = nil
          @@per_tenant_gateways_cache[kb_tenant_id] = nil
        end

        private

        def extract_gateway_config(config)
          gateway_configs = config[@@gateway_name.to_sym]
          global_defaults = @@glob_config[@@gateway_name.to_sym] || {}
          # Provided configuration is the same of global (i.e. no tenant specific configuration)
          unless global_defaults.is_a?(Hash)
            @@logger.warn "Ignoring #{@@gateway_name} global configuration. Invalid format, expecting a Hash."
            global_defaults = {}
          end

          gateways_config = {}
          if gateway_configs.is_a?(Array)
            default_gateway = nil
            gateway_configs.each_with_index do |gateway_config, idx|
              gateway_config = global_defaults.merge(gateway_config)
              gateway_account_id = gateway_config[:account_id]
              if gateway_account_id.nil?
                @@logger.warn "Skipping config #{gateway_config} -- missing :account_id"
              else
                gateways_config[gateway_account_id.to_sym] = Gateway.wrap(gateway_builder, gateway_config, @@logger)
                default_gateway = gateways_config[gateway_account_id.to_sym] if idx == 0
              end
            end
            gateways_config[:default] = default_gateway if gateways_config[:default].nil?
          else
            # We assume the configuration should never be nil (if you really do have a use-case, just specify a dummy config)
            if gateway_configs.nil?
              @@logger.warn "Unable to configure gateway #{@@gateway_name}, invalid configuration: #{config}"
            else
              gateways_config[:default] = Gateway.wrap(@@gateway_builder, global_defaults.merge(gateway_configs), @@logger)
            end
          end
          gateways_config
        end

        def get_tenant_config(kb_tenant_id)
          if @@per_tenant_config_cache[kb_tenant_id].nil?
            # Make the api api to verify if there is a per tenant value
            context = @@kb_apis.create_context(kb_tenant_id) if kb_tenant_id
            values = @@kb_apis.tenant_user_api.get_tenant_values_for_key(@@config_key_name, context) if context
            # If we have a per tenant value, insert it into the cache
            if values && values[0]
              parsed_config = YAML.load(values[0])
              @@per_tenant_config_cache[kb_tenant_id] = parsed_config
              # Otherwise, add global config so we don't have to make the tenant call on each operation
            else
              @@per_tenant_config_cache[kb_tenant_id] = @@glob_config
            end
          end
          # Return value from cache in any case
          @@per_tenant_config_cache[kb_tenant_id]
        end

        def initialize_from_global_config!(config_file)
          # Look for global config
          if !config_file.blank? && Pathname.new(config_file).file?
            @@glob_config = Properties.new(config_file)
            @@glob_config.parse!
            @@glob_config = @@glob_config.to_hash
          else
            @@glob_config = {}
          end

          @@logger.level = Logger::DEBUG if (@@glob_config[:logger] || {})[:debug]

          @@glob_currency_conversions = @@glob_config[:currency_conversions]

          initialize_active_record

          initialize_active_merchant

          @@initialized = true
        end

        def initialize_active_record
          begin
            require 'active_record'
            require 'arjdbc' if defined?(JRUBY_VERSION)
            db_config = @@glob_config[:database]

            if db_config.nil?
              # Sane defaults for running as a Kill Bill plugin
              db_config = {
                  :adapter              => :mysql,
                  # See KillbillActivator#KILLBILL_OSGI_JDBC_JNDI_NAME
                  :jndi                 => 'killbill/osgi/jdbc',
                  # See https://github.com/kares/activerecord-bogacs
                  :pool                 => false,
                  # Since AR-JDBC 1.4, to disable session configuration
                  :configure_connection => false
              }
            end

            if defined?(JRUBY_VERSION) && db_config.is_a?(Hash)
              if db_config[:jndi]
                # Lookup the DataSource object once, for performance reasons
                begin
                  db_config[:data_source] = Java::JavaxNaming::InitialContext.new.lookup(db_config[:jndi].to_s)
                  db_config.delete(:jndi)
                rescue Java::javax.naming.NamingException => e
                  # See https://github.com/killbill/killbill-plugin-framework-ruby/issues/39
                  @@logger.warn "Unable to lookup JNDI DataSource (yet?): #{e}" unless defined?(JBUNDLER_CLASSPATH)
                end
              end

              # we accept a **pool: false** configuration in which case we
              # the built-in pool is replaced with a false one (under JNDI) :
              if db_config[:pool] == false && ( db_config[:jndi] || db_config[:data_source] )
                begin; require 'active_record/bogacs'
                pool_class = ::ActiveRecord::Bogacs::FalsePool
                ::ActiveRecord::ConnectionAdapters::ConnectionHandler.connection_pool_class = pool_class
                rescue LoadError
                  db_config.delete(:pool) # do not confuse AR's built-in pool
                  @@logger.warn "ActiveRecord-Bogacs missing, will use default (built-in) AR pool."
                end
              end
            end
            ::ActiveRecord::Base.establish_connection(db_config)
            ::ActiveRecord::Base.logger = @@logger
          rescue => e
            @@logger.warn "Unable to establish a database connection: #{e}"
          end
        end

        # Configure global properties
        # It would be nice to fix ActiveMerchant to make these configurable on a per instance basis
        def initialize_active_merchant
          require 'active_merchant'

          ::ActiveMerchant::Billing::Gateway.logger = @@logger

          am_config = @@glob_config[@@gateway_name.to_sym]
          if am_config.is_a?(Array)
            default_gateway_config = {}
            am_config.each_with_index do |gateway_config, idx|
              gateway_account_id = gateway_config[:account_id]
              if gateway_account_id.nil?
                @@logger.warn "Skipping config #{gateway_config} -- missing :account_id"
              else
                default_gateway_config = gateway_config if idx == 0 || gateway_account_id == :default
              end
            end
            am_config = default_gateway_config
          end
          am_config ||= {
              # Sane defaults
              :test => true
          }

          if am_config[:test]
            ::ActiveMerchant::Billing::Base.mode = :test
          end

          if am_config[:log_file]
            ::ActiveMerchant::Billing::Gateway.wiredump_device = File.open(am_config[:log_file], 'w')
          else
            log_method = am_config[:quiet] ? :debug : :info
            ::ActiveMerchant::Billing::Gateway.wiredump_device = ::Killbill::Plugin::ActiveMerchant::Utils::KBWiredumpDevice.new(@@logger, log_method)
          end
          ::ActiveMerchant::Billing::Gateway.wiredump_device.sync = true

          ::ActiveMerchant::Billing::Gateway.open_timeout  = am_config[:open_timeout] unless am_config[:open_timeout].nil?
          ::ActiveMerchant::Billing::Gateway.read_timeout  = am_config[:read_timeout] unless am_config[:read_timeout].nil?
          ::ActiveMerchant::Billing::Gateway.retry_safe    = am_config[:retry_safe] unless am_config[:retry_safe].nil?
          ::ActiveMerchant::Billing::Gateway.ssl_strict    = am_config[:ssl_strict] unless am_config[:ssl_strict].nil?
          ::ActiveMerchant::Billing::Gateway.ssl_version   = am_config[:ssl_version] unless am_config[:ssl_version].nil?
          ::ActiveMerchant::Billing::Gateway.max_retries   = am_config[:max_retries] unless am_config[:max_retries].nil?
          ::ActiveMerchant::Billing::Gateway.proxy_address = am_config[:proxy_address] unless am_config[:proxy_address].nil?
          ::ActiveMerchant::Billing::Gateway.proxy_port    = am_config[:proxy_port] unless am_config[:proxy_port].nil?

          # Configure the ActiveMerchant HTTP backend
          connection_type = (@@glob_config[:active_merchant] || am_config)[:connection_type]
          if connection_type == :typhoeus
            require 'killbill/ext/active_merchant/typhoeus_connection'
          end
        end
      end
    end
  end
end
