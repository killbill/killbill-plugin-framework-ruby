require 'killbill/plugin'

module Killbill
  module Plugin
    class CatalogPluginApi < Notification

      class OperationUnsupported < NotImplementedError
      end

      def get_versioned_plugin_catalog(properties, context)
        raise OperationUnsupported
      end
    end
  end
end
