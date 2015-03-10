require 'logger'

module Killbill
  module Plugin
    module ActiveMerchant
      mattr_reader :config
      mattr_reader :currency_conversions
      mattr_reader :gateways
      mattr_reader :initialized
      mattr_reader :kb_apis
      mattr_reader :logger

      def self.initialize!(gateway_builder, gateway_name, logger, config_file, kb_apis)
        @@config = Properties.new(config_file)
        @@config.parse!

        @@logger           = logger
        @@logger.log_level = Logger::DEBUG if (@@config[:logger] || {})[:debug]

        @@currency_conversions = @@config[:currency_conversions]
        @@kb_apis              = kb_apis

        @@gateways      = {}
        gateway_configs = @@config[gateway_name.to_sym]
        if gateway_configs.is_a?(Array)
          default_gateway = nil
          gateway_configs.each_with_index do |gateway_config, idx|
            gateway_account_id = gateway_config[:account_id]
            if gateway_account_id.nil?
              @@logger.warn "Skipping config #{gateway_config} -- missing :account_id"
            else
              @@gateways[gateway_account_id.to_sym] = Gateway.wrap(gateway_builder, logger, gateway_config)
              default_gateway                       = @@gateways[gateway_account_id.to_sym] if idx == 0
            end
          end
          @@gateways[:default] = default_gateway if @@gateways[:default].nil?
        else
          @@gateways[:default] = Gateway.wrap(gateway_builder, logger, gateway_configs)
        end

        begin
          require 'active_record'
          require 'arjdbc' if defined?(JRUBY_VERSION)
          db_config = @@config[:database]

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
        connection_type = (@@config[:active_merchant] || {})[:connection_type]
        if connection_type == :typhoeus
          require 'killbill/ext/active_merchant/typhoeus_connection'
        end

        @@initialized = true
      end

      def self.converted_currency(currency)
        currency_sym = currency.to_s.upcase.to_sym
        @@currency_conversions && @@currency_conversions[currency_sym]
      end
    end
  end
end
