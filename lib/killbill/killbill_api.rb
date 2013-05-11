
Dir['gen/*.rb', ".rb"].collect { |e| e.sub(/\.\w+$/,'')}.each { |x| require "killbill/#{x}" }

module Killbill
  module Plugin

    #
    # Represents a subset of the Killbill Apis offered to the ruby plugins
    #
    class KillbillApi

      def initialize(japi_proxy)
        @japi_proxy = japi_proxy
      end

      def create_account(account_data)
        @japi_proxy.proxy_api(__method__, account_data)
      end

      def get_account_by_id(account_id)
        @japi_proxy.proxy_api(__method__, account_id)
      end

    end
  end
end
