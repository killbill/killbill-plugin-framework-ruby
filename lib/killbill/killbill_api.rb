module Killbill
  module Plugin

    #
    # Represents a subset of the Killbill Apis offered to the ruby plugins
    #
    class KillbillApi

      def initialize(plugin_name, java_service_map)
        @plugin_name = plugin_name
        @services = {}
        java_service_map.each do |k,v|
          @services[k] = create_proxy_api(k, v)
        end
      end

      #
      # Returns the proxy to the java api
      #
      def method_missing(m, *args, &block)
        # m being a symbol, to_s is required for Ruby 1.8
        return @services[m.to_s] if @services.include? m.to_s
        raise NoMethodError.new("undefined method `#{m}' for #{self}")
      end

      private

      def create_proxy_api(api_name, java_api)
        proxy_class_name = "Killbill::Plugin::Api::#{api_name.split('_').map{|e| e.capitalize}.join}".new(java_api)
        proxy_class_name.to_class.new(java_api)
      end

    end
  end
end
