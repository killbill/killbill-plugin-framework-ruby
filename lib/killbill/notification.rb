require 'killbill/plugin'

module Killbill
  module Plugin
    class Notification < PluginBase

      # Override this method in your plugin to act upon received events
      def on_event(event)
        # no-op
      end

    end
  end
end
