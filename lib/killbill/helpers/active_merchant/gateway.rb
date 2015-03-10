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
          else
            log_method = config[:quiet] ? :debug : :info
            ::ActiveMerchant::Billing::Gateway.wiredump_device = ::Killbill::Plugin::ActiveMerchant::Utils::KBWiredumpDevice.new(logger, log_method)
          end
          ::ActiveMerchant::Billing::Gateway.wiredump_device.sync = true

          ::ActiveMerchant::Billing::Gateway.open_timeout  = config[:open_timeout] unless config[:open_timeout].nil?
          ::ActiveMerchant::Billing::Gateway.read_timeout  = config[:read_timeout] unless config[:read_timeout].nil?
          ::ActiveMerchant::Billing::Gateway.retry_safe    = config[:retry_safe] unless config[:retry_safe].nil?
          ::ActiveMerchant::Billing::Gateway.ssl_strict    = config[:ssl_strict] unless config[:ssl_strict].nil?
          ::ActiveMerchant::Billing::Gateway.ssl_version   = config[:ssl_version] unless config[:ssl_version].nil?
          ::ActiveMerchant::Billing::Gateway.max_retries   = config[:max_retries] unless config[:max_retries].nil?
          ::ActiveMerchant::Billing::Gateway.proxy_address = config[:proxy_address] unless config[:proxy_address].nil?
          ::ActiveMerchant::Billing::Gateway.proxy_port    = config[:proxy_port] unless config[:proxy_port].nil?

          Gateway.new(config, gateway_builder.call(config))
        end

        attr_reader :config

        def initialize(config, am_gateway)
          @config = config
          @gateway = am_gateway
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
