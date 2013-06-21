require 'java'

require 'pathname'

require 'killbill/http_servlet'
require 'killbill/creator'

include Java

module Killbill
  # There are various types of plugins one can write for Killbill:
  #
  #   1)  notifications plugins, which listen to external bus events and can react to it
  #   2)  payment plugins, which are used to issue payments against a payment gateway
  module Plugin
    class JPlugin


      attr_reader :delegate_plugin,
                  # Called by the Killbill lifecycle to register the servlet
                  :rack_handler

      # Called by the Killbill lifecycle when initializing the plugin
      def start_plugin
        @delegate_plugin.start_plugin
        configure_rack_handler
      end

      # Called by the Killbill lifecycle when stopping the plugin
      def stop_plugin
        unconfigure_rack_handler
        @delegate_plugin.stop_plugin
      end

      def is_active
        @delegate_plugin.active
      end

      # Called by the Killbill lifecycle when instantiating the plugin
      def initialize(plugin_class_name, services = {})
        @delegate_plugin = Creator.new(plugin_class_name).create(services)
      end

      def logger
        require 'logger'
        @delegate_plugin.nil? ? ::Logger.new(STDOUT) : @delegate_plugin.logger
      end

      protected

      def configure_rack_handler
        config_ru = Pathname.new("#{@delegate_plugin.root}/config.ru").expand_path
        if config_ru.file?
          logger.info "Found Rack configuration file at #{config_ru.to_s}"
          @rack_handler = Killbill::Plugin::RackHandler.instance
          @rack_handler.configure(logger, config_ru.to_s) unless @rack_handler.configured?
        else
          logger.info "No Rack configuration file found at #{config_ru.to_s}"
          nil
        end
      end

      def unconfigure_rack_handler
        @rack_handler.unconfigure unless @rack_handler.nil?
      end
    end
  end
end
