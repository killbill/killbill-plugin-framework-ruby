module Killbill
  module Plugin
    module ActiveMerchant
      require 'active_merchant'

      class Gateway
        def self.wrap(gateway_builder, config, logger)
          Gateway.new(config, gateway_builder.call(config), logger)
        end

        attr_reader :config

        def initialize(config, am_gateway, logger)
          @config = config
          @gateway = am_gateway
          @logger = logger

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
          options = {}

          # The options hash should be the last argument, iterate through all to be safe
          args.reverse.each do |arg|
            if arg.respond_to?(:has_key?)
              options = arg
              return ::ActiveMerchant::Billing::Response.new(true, 'Skipped Gateway call') if Utils.normalized(arg, :skip_gw)
            end
          end

          @gateway.send(m, *args, &block)
        rescue ::ActiveMerchant::ConnectionError => e
          # Need to unwrap it
          until e.triggering_exception.nil?
            e = e.triggering_exception
            break unless e.is_a?(::ActiveMerchant::ConnectionError)
          end
          handle_exception(e, options)
        rescue => e
          handle_exception(e, options)
        end

        def respond_to?(method, include_private=false)
          @gateway.respond_to?(method, include_private) || super
        end

        private

        UNKNOWN_CONNECTION_ERRORS = [
            # Corrupted stream (e.g. Zlib::BufError)
            ::ActiveMerchant::InvalidResponseError,
            # We attempted a payment, but the gateway replied >= 300. This is gateway specific, hopefully the individual
            # gateway implementation knows how to rescue from it and this is not risen
            ::ActiveMerchant::ResponseError,
            # Should not be risen directly
            ::ActiveMerchant::RetriableConnectionError,
            ::ActiveMerchant::ActiveMerchantError
        ]

        PROBABLY_UNKNOWN_CONNECTION_ERRORS = [
            EOFError,
            Errno::ECONNRESET,
            Timeout::Error,
            Errno::ETIMEDOUT
        ]

        SAFE_CONNECTION_ERRORS = [
            SocketError,
            Errno::EHOSTUNREACH,
            Errno::ECONNREFUSED,
            ::OpenSSL::SSL::SSLError,
            # Invalid certificate (e.g. OpenSSL::X509::CertificateError)
            ::ActiveMerchant::ClientCertificateError
        ]

        # See https://github.com/killbill/killbill-plugin-framework-ruby/issues/44
        def handle_exception(e, options = {})
          message = "#{e.class} #{e.message}"

          if SAFE_CONNECTION_ERRORS.include?(e.class)
            # Easy case: we didn't attempt the payment
            @logger.warn("Connection error with the gateway: #{message}")
            payment_plugin_status = :CANCELED
          else
            # For anything else, tell Kill Bill we don't know. If the gateway supports retrieving a payment status,
            # the plugin should implement get_payment_info accordingly for the Janitor.
            # Otherwise, the transaction will need to be fixed manually using the admin APIs.

            # Note that PROBABLY_UNKNOWN_CONNECTION_ERRORS/UNKNOWN_CONNECTION_ERRORS are a bit _better_, as they can be expected and we don't have any control over them.
            # Any other exception might be caused by a bug in our code!
            if PROBABLY_UNKNOWN_CONNECTION_ERRORS.include?(e.class) || UNKNOWN_CONNECTION_ERRORS.include?(e.class)
              @logger.warn("Unstable connection with the gateway: #{message}")
            else
              @logger.warn("Unexpected exception: #{message}\n#{e.backtrace.join("\n")}")
            end

            # Allow clients to force a PLUGIN_FAILURE instead of UNKNOWN (the default is a conservative behavior)
            payment_plugin_status = Utils.normalized(options, :connection_errors_safe) ? :CANCELED : :UNDEFINED
          end

          response_message = { :exception_class => e.class.to_s, :exception_message => e.message, :payment_plugin_status => payment_plugin_status }.to_json
          ::ActiveMerchant::Billing::Response.new(false, response_message)
        end
      end
    end
  end
end
