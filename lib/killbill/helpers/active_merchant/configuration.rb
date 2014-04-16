require 'logger'

module Killbill
  module Plugin
    module ActiveMerchant
      mattr_reader :config
      mattr_reader :currency_conversions
      mattr_reader :gateway
      mattr_reader :initialized
      mattr_reader :kb_apis
      mattr_reader :logger
      mattr_reader :test

      def self.initialize!(gateway_builder, gateway_name, logger, config_file, kb_apis)
        @@config = Properties.new(config_file)
        @@config.parse!

        @@currency_conversions = @@config[:currency_conversions]
        @@kb_apis = kb_apis
        @@test = @@config[gateway_name][:test]

        @@gateway = Gateway.wrap(gateway_builder, @@config[gateway_name.to_sym])

        @@logger = logger
        @@logger.log_level = Logger::DEBUG if (@@config[:logger] || {})[:debug]

        if defined?(JRUBY_VERSION)
          begin
            # See https://github.com/jruby/activerecord-jdbc-adapter/issues/302
            require 'jdbc/mysql'
            ::Jdbc::MySQL.load_driver(:require) if ::Jdbc::MySQL.respond_to?(:load_driver)
          rescue => e
            @@logger.warn "Unable to load the JDBC driver: #{e}"
          end
        end

        begin
          require 'active_record'
          ::ActiveRecord::Base.establish_connection(@@config[:database])
          ::ActiveRecord::Base.logger = @@logger
        rescue => e
          @@logger.warn "Unable to establish a database connection: #{e}"
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
