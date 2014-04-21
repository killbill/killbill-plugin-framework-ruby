module Killbill
  module Plugin
    module ActiveMerchant
      require 'active_merchant'

      class Gateway
        def self.wrap(gateway_builder, config)
          if config[:test]
            ::ActiveMerchant::Billing::Base.mode = :test
          end

          if config[:log_file]
            ::ActiveMerchant::Billing::Gateway.wiredump_device = File.open(config[:log_file], 'w')
            ::ActiveMerchant::Billing::Gateway.wiredump_device.sync = true
          end

          Gateway.new(gateway_builder.call(config))
        end

        def initialize(am_gateway)
          @gateway = am_gateway
        end

        # Unfortunate name...
        def capture(money, authorization, options = {})
          @gateway.capture(money, authorization, options)
        end

        def method_missing(m, *args, &block)
          @gateway.send(m, *args, &block)
        end
      end
    end
  end
end
