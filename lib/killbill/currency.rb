require 'killbill/plugin'

module Killbill
  module Plugin
    class Currency < PluginBase

      class OperationUnsupportedError < NotImplementedError
      end

      def get_base_currencies(options = {})
        raise OperationUnsupportedError
      end

      def get_latest_conversion_date(base_currency, options = {})
        raise OperationUnsupportedError
      end

      def get_conversion_dates(base_currency, options = {})
        raise OperationUnsupportedError
      end

      def get_current_rates(base_currency, options = {})
        raise OperationUnsupportedError
      end

      def get_rates(base_currency, conversion_date, options = {})
        raise OperationUnsupportedError
      end

      # Override this method in your plugin to act upon received events
      def on_event(event)
        # No-op by default
      end


    end
  end
end
