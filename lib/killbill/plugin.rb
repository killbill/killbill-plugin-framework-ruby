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

      attr_accessor :account_user_api,
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

      # Called by the Killbill lifecycle when instantiating the plugin
      def initialize(apis_map = {})
        @active = false

        apis_map.each do |api_name, api_instance|
          begin
            self.send("#{api_name}=", api_instance)
          rescue NoMethodError
            warn "Ignoring unsupported API: #{api_name}"
          end
        end
      end

      # Called by the Killbill lifecycle to register the servlet
      def rack_handler
        Killbill::Plugin::RackHandler.instance
      end

      class APINotAvailableError < NotImplementedError
      end

      def method_missing(m, *args, &block)
        raise APINotAvailableError.new("API #{m} is not available") if m =~ /_api$/
      end

    end
  end
end
