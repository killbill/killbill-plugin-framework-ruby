require 'logger'
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

          initialize_from_global_config!(gateway_builder, gateway_name, logger, config_file)
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

        def config(kb_tenant_id=nil)
          get_tenant_config(kb_tenant_id)
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
          gateways_config = {}
          gateway_configs = config[@@gateway_name.to_sym]
          if gateway_configs.is_a?(Array)
            default_gateway = nil
            gateway_configs.each_with_index do |gateway_config, idx|
              gateway_account_id = gateway_config[:account_id]
              if gateway_account_id.nil?
                @@logger.warn "Skipping config #{gateway_config} -- missing :account_id"
              else
                gateways_config[gateway_account_id.to_sym] = Gateway.wrap(gateway_builder, logger, gateway_config)
                default_gateway = gateways_config[gateway_account_id.to_sym] if idx == 0
              end
            end
            gateways_config[:default] = default_gateway if gateways_config[:default].nil?
          else
            gateways_config[:default] = Gateway.wrap(@@gateway_builder, logger, gateway_configs)
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

        def initialize_from_global_config!(gateway_builder, gateway_name, logger, config_file)
          # Look for global config
          @@glob_config = Properties.new(config_file)
          @@glob_config.parse!

          @@logger.log_level = Logger::DEBUG if (@@glob_config[:logger] || {})[:debug]

          @@glob_currency_conversions = @@glob_config[:currency_conversions]

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
                  @@logger.warn "Unable to lookup JNDI DataSource (yet?): #{e}"
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

          # Configure the ActiveMerchant HTTP backend
          connection_type = (@@glob_config[:active_merchant] || {})[:connection_type]
          if connection_type == :typhoeus
            require 'killbill/ext/active_merchant/typhoeus_connection'
          end

          @@initialized = true
        end
      end
    end
  end
end
