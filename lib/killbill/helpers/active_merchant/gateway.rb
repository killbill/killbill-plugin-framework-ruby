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

          ::ActiveMerchant::Billing::Gateway.open_timeout  = config[:open_timeout] if config[:open_timeout]
          ::ActiveMerchant::Billing::Gateway.read_timeout  = config[:read_timeout] if config[:read_timeout]
          ::ActiveMerchant::Billing::Gateway.retry_safe    = config[:retry_safe] if config[:retry_safe]
          ::ActiveMerchant::Billing::Gateway.ssl_strict    = config[:ssl_strict] if config[:ssl_strict]
          ::ActiveMerchant::Billing::Gateway.ssl_version   = config[:ssl_version] if config[:ssl_version]
          ::ActiveMerchant::Billing::Gateway.max_retries   = config[:max_retries] if config[:max_retries]
          ::ActiveMerchant::Billing::Gateway.proxy_address = config[:proxy_address] if config[:proxy_address]
          ::ActiveMerchant::Billing::Gateway.proxy_port    = config[:proxy_port] if config[:proxy_port]

          Gateway.new(config, gateway_builder.call(config))
        end

        attr_reader :config

        def initialize(config, am_gateway)
          @config = config
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
