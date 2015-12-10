require 'killbill/killbill_logger'

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

      # Extra services
      attr_accessor :root,
                    :plugin_name,
                    :logger,
                    :conf_dir,
                    :clock,
                    :kb_apis

      # Called by the Killbill lifecycle when instantiating the plugin
      def initialize()
        @active = false
      end


      def logger=(logger)
        # logger is an OSGI LogService in the Killbill environment. For testing purposes,
        # allow delegation to a standard logger
        @logger = logger.respond_to?(:info) ? logger : Killbill::Plugin::KillbillLogger.new(logger)
      end

      def logger
        @logger ||= Logger.new(STDOUT)
      end

      # Will be called by each thread before returning to Killbill
      def after_request
      end
    end
  end
end
