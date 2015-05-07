module Killbill
  module Plugin
    module ActiveMerchant
      require 'active_merchant'

      class Gateway
        def self.wrap(gateway_builder, config)
          Gateway.new(config, gateway_builder.call(config))
        end

        attr_reader :config

        def initialize(config, am_gateway)
          @config = config
          @gateway = am_gateway

          # Override urls if needed (there is no easy way to do it earlier, because AM uses class_attribute)
          @gateway.class.test_url = @config[:test_url] unless @config[:test_url].nil?
          @gateway.class.live_url = @config[:live_url] unless @config[:live_url].nil?
        end

        #
        # Materialize the most common operations - this is for performance reasons
        #

        def store(*args, &block)
          method_missing(:store, *args, &block)
        end

        def unstore(*args, &block)
          method_missing(:unstore, *args, &block)
        end

        def authorize(*args, &block)
          method_missing(:authorize, *args, &block)
        end

        # Unfortunate name...
        def capture(*args, &block)
          method_missing(:capture, *args, &block)
        end

        def purchase(*args, &block)
          method_missing(:purchase, *args, &block)
        end

        def void(*args, &block)
          method_missing(:void, *args, &block)
        end

        def credit(*args, &block)
          method_missing(:credit, *args, &block)
        end

        def refund(*args, &block)
          method_missing(:refund, *args, &block)
        end

        def method_missing(m, *args, &block)
          # The options hash should be the last argument, iterate through all to be safe
          args.reverse.each do |arg|
            if arg.respond_to?(:has_key?) && Utils.normalized(arg, :skip_gw)
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
