require 'killbill/http_servlet'
require 'killbill/logger'

module Killbill
  # There are various types of plugins one can write for Killbill:
  #
  #   1)  notifications plugins, which listen to external bus events and can react to it
  #   2)  payment plugins, which are used to issue payments against a payment gateway
  module Plugin
    class PluginBase

      attr_reader :active

      # Called by the Killbill lifecycle when initializing the plugin
      def start_plugin
        @active = true
      end

      # Called by the Killbill lifecycle when stopping the plugin
      def stop_plugin
        @active = false
      end

      attr_writer :account_user_api,
                  :analytics_sanity_api,
                  :analytics_user_api,
                  :catalog_user_api,
                  :entitlement_migration_api,
                  :entitlement_timeline_api,
                  :entitlement_transfer_api,
                  :entitlement_user_api,
                  :invoice_migration_api,
                  :invoice_payment_api,
                  :invoice_user_api,
                  :meter_user_api,
                  :overdue_user_api,
                  :payment_api,
                  :tenant_user_api,
                  :usage_user_api,
                  :audit_user_api,
                  :custom_field_user_api,
                  :export_user_api,
                  :tag_user_api
      # Extra services
      attr_accessor :root,
                    :logger

      # Called by the Killbill lifecycle when instantiating the plugin
      def initialize(services = {})
        @active = false

        services.each do |service_name, service_instance|
          begin
            self.send("#{service_name}=", service_instance)
          rescue NoMethodError
            warn "Ignoring unsupported service: #{service_name}"
          end
        end
      end

      def logger=(logger)
        @logger = Killbill::Plugin::Logger.new(logger)
      end

      # Called by the Killbill lifecycle to register the servlet
      def rack_handler
        config_ru = Pathname.new("#{@root}/config.ru").expand_path
        if config_ru.file?
          @logger.info "Found Rack configuration file at #{config_ru.to_s}"
          instance = Killbill::Plugin::RackHandler.instance
          instance.configure(@logger, config_ru.to_s) unless instance.configured?
          instance
        else
          @logger.info "No Rack configuration file found at #{config_ru.to_s}"
          nil
        end
      end

      class APINotAvailableError < NotImplementedError
      end

      def method_missing(m, *args, &block)
        # m being a symbol, to_s is required for Ruby 1.8
        if m.to_s =~ /_api$/
          api = self.instance_variable_get("@#{m.to_s}")
          if api.nil?
            raise APINotAvailableError.new("API #{m} is not available")
          else
            api
          end
        end
      end
    end
  end
end
