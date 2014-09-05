module Killbill
  module Plugin
    module ActiveMerchant
      require 'active_merchant'

      class Gateway
        def self.wrap(gateway_builder, logger, config)
          ::ActiveMerchant::Billing::Gateway.logger = logger

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
          method_missing(:capture, money, authorization, options)
        end

        def method_missing(m, *args, &block)
          # The options hash should be the last argument, iterate through all to be safe
          args.reverse.each do |arg|
            if arg.respond_to?(:has_key?) && arg.has_key?(:skip_gw)
              return ::ActiveMerchant::Billing::Response.new(true, 'Skipped Gateway call')
            end
          end

          @gateway.send(m, *args, &block)
        end

        def respond_to?(method, include_private=false)
          @gateway.respond_to?(method, include_private) || super
        end
      end
    end
  end
end
