require 'logger'
require 'pathname'

module Killbill
  module Plugin
    module ActiveMerchant

      mattr_reader :glob_config
      mattr_reader :glob_currency_conversions
      mattr_reader :glob_gateways

      mattr_reader :initialized
      mattr_reader :kb_apis
      mattr_reader :plugin_config_key
      mattr_reader :gateway_name
      mattr_reader :gateway_builder
      mattr_reader :logger
      mattr_reader :plugin_name


      class << self

        def initialize!(gateway_builder, gateway_name, logger, root, config_file, kb_apis)

          @@logger = logger
          @@kb_apis = kb_apis
          @@gateway_name = gateway_name
          @@gateway_builder = gateway_builder
          @@plugin_name = get_plugin_name(root)
          @@plugin_config_key = "PLUGIN_CONFIG_#{@@plugin_name}"

          if defined?(JRUBY_VERSION)
            begin
              # See https://github.com/jruby/activerecord-jdbc-adapter/issues/302
              require 'jdbc/mysql'
              ::Jdbc::MySQL.load_driver(:require) if ::Jdbc::MySQL.respond_to?(:load_driver)
            rescue => e
              @@logger.warn "Unable to load the JDBC driver: #{e}"
            end
          end

          initialize_from_global_config!(gateway_builder, gateway_name, logger, config_file)
        end


        def gateways(kb_tenant_id=nil)
          tenant_config = get_tenant_config(kb_tenant_id)
          if tenant_config
            extract_gateway_config(tenant_config)
          else
            @@glob_gateways
          end
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
          tenant_config = get_tenant_config(kb_tenant_id)
          if tenant_config
            tenant_config
          else
            @@glob_config
          end
        end

        def converted_currency(currency, kb_tenant_id=nil)
          currency_sym = currency.to_s.upcase.to_sym
          tmp = currency_conversions(kb_tenant_id)
          tmp && tmp[currency_sym]
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
          context = @@kb_apis.create_context(kb_tenant_id) if kb_tenant_id
          values = @@kb_apis.tenant_user_api.get_tenant_values_for_key(@@plugin_config_key, context) if context
          return YAML.load(values[0]) if values && values[0]
          nil
        end

        def initialize_from_global_config!(gateway_builder, gateway_name, logger, config_file)
          # Look for global config
          @@glob_config = Properties.new(config_file)
          @@glob_config.parse!

          @@logger.log_level = Logger::DEBUG if (@@glob_config[:logger] || {})[:debug]

          @@glob_currency_conversions = @@glob_config[:currency_conversions]
          @@glob_gateways = extract_gateway_config(@@glob_config)

          begin
            require 'active_record'
            ::ActiveRecord::Base.establish_connection(@@glob_config[:database])
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

        # The plugin_name is computed by Kill Bill by looking at the file system when discovering the plugin
        # The 'root' value points to '/.../plugin_name/plugin_version'
        def get_plugin_name(root)
          p = Pathname.new(root)
          p.split[0].split[1].to_s
        end
      end
    end
  end
end
