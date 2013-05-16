

module Killbill
  module Plugin

    #
    # Represents a subset of the Killbill Apis offered to the ruby plugins
    #
    class KillbillApi


      def initialize(japi_proxy)
        @japi_proxy = japi_proxy
        EXPORT_KILLBILL_API.each do |api|

        end
      end

      def method_missing(m, *args, &block)
        # m being a symbol, to_s is required for Ruby 1.8
        puts "Got missing method #{m.to_s}"
        return @japi_proxy.proxy_api(m.to_s, *args) if EXPORT_KILLBILL_API.include? m.to_s
        raise NoMethodError.new("undefined method `#{m}' for #{self}")
      end

    end
  end
end
