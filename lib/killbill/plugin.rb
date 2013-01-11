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

    end
  end
end
