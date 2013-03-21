require 'killbill/http_servlet'
require 'killbill/logger'

module Killbill
  # There are various types of plugins one can write for Killbill:
  #
  #   1)  notifications plugins, which listen to external bus events and can react to it
  #   2)  payment plugins, which are used to issue payments against a payment gateway
  module Plugin
    class JPlugin

      attr_reader :delegate_plugin

      # Called by the Killbill lifecycle when initializing the plugin
      def start_plugin
        @delegate_plugin.start_plugin
      end

      # Called by the Killbill lifecycle when stopping the plugin
      def stop_plugin
        @delegate_plugin.stop_plugin
      end

      # Called by the Killbill lifecycle when instantiating the plugin
      def initialize(plugin_class_name, services = {})
        @delegate_plugin = Creator.new(plugin_class_name).create(services)
      end

      # Called by the Killbill lifecycle to register the servlet
      def rack_handler
        config_ru = Pathname.new("#{@delegate_plugin.root}/config.ru").expand_path
        if config_ru.file?
          @delegate_plugin.logger.info "Found Rack configuration file at #{config_ru.to_s}"
          instance = Killbill::Plugin::RackHandler.instance
          instance.configure(@logger, config_ru.to_s) unless instance.configured?
          instance
        else
          @delegate_plugin.logger.info "No Rack configuration file found at #{config_ru.to_s}"
          nil
        end
      end

    end
  end
end
