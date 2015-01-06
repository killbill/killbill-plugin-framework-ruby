require 'benchmark'
require 'openssl' # active_utils internals assume OpenSSL loaded
require 'active_utils'
require 'typhoeus'

module ActiveMerchant
  Connection.class_eval do # force auto-load (loads network_connection_retries)

    def request(method, body, headers = {})
      request_start = Time.now.to_f

      retry_exceptions(:max_retries => max_retries, :logger => logger, :tag => tag) do
        begin
          debug "connection_http_method=#{method.to_s.upcase} connection_uri=#{endpoint}", tag

          result   = nil
          realtime = Benchmark.realtime do
            options         = {:method => method, :headers => headers, :connecttimeout => open_timeout}
            options[:body]  = body if body
            options[:proxy] = proxy_address if proxy_address
            options[:proxy] += ":#{proxy_port}" if proxy_address and proxy_port
            result          = http(endpoint.to_s, options)
          end

          debug '--> response_code=%d (body_length=%d total_time=%.4fs realtime=%.4fs)' % [result.code, result.body ? result.body.length : 0, result.total_time, realtime], tag
          result
        end
      end
    ensure
      debug 'connection_request_total_time=%.4fs' % [Time.now.to_f - request_start], tag
    end

    private

    def http(endpoint, options = {})
      configure_ssl(options)

      request = ::Typhoeus::Request.new(endpoint, options)
      configure_debugging(request)

      hydra = ::Typhoeus::Hydra.hydra
      hydra.queue request
      hydra.run

      request.response
    end

    def configure_debugging(request)
      request.on_complete do |response|
        wiredump_device << 'Request: '
        wiredump_device << response.request.base_url
        wiredump_device << ' '
        wiredump_device << response.request.options
        wiredump_device << "\nResponse: "
        wiredump_device << response.return_code
        wiredump_device << ' '
        wiredump_device << response.return_message
        wiredump_device << ' '
        wiredump_device << response.response_headers
        wiredump_device << ' '
        wiredump_device << response.response_body
        wiredump_device << "\n\n"
      end
    end

    def configure_ssl(options)
      return unless endpoint.scheme == 'https'

      if verify_peer
        options[:ssl_verifypeer] ||= true
        options[:ssl_verifyhost] ||= 2
        # ca_file / ca_path configured in libcurl
      else
        options[:ssl_verifypeer] ||= false
        options[:ssl_verifyhost] ||= 0
      end
    end

    def log_with_retry_details(logger, attempts, time, message, tag)
      NetworkConnectionRetries.log(logger, :debug, "connection_attempt=%d connection_request_time=%.4fs connection_msg=\"%s\"" % [attempts, time, message], tag)
    end
  end
end
