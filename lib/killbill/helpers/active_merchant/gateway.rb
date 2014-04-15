module Killbill
  module Plugin
    module ActiveMerchant
      require 'active_merchant'

      class Gateway
        def self.wrap(am_gateway, config)
          if config[:test]
            ::ActiveMerchant::Billing::Base.mode = :test
          end

          if config[:log_file]
            ::ActiveMerchant::Billing::Base.wiredump_device = File.open(config[:log_file], 'w')
            ::ActiveMerchant::Billing::Base.wiredump_device.sync = true
          end

          Gateway.new(am_gateway)
        end

        def initialize(am_gateway)
          @gateway = am_gateway
        end

        def method_missing(m, *args, &block)
          @gateway.send(m, *args, &block)
        end
      end
    end
  end
end
