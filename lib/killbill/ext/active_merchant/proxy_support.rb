require 'active_utils/common/posts_data'

# Pass the proxy details to the connection object - see https://github.com/Shopify/active_utils/pull/44
module ActiveMerchant #:nodoc:
  module PostsData #:nodoc:

    def self.included(base)
      base.superclass_delegating_accessor :ssl_strict
      base.ssl_strict = true

      base.superclass_delegating_accessor :ssl_version
      base.ssl_version = nil

      base.class_attribute :retry_safe
      base.retry_safe = false

      base.superclass_delegating_accessor :open_timeout
      base.open_timeout = 60

      base.superclass_delegating_accessor :read_timeout
      base.read_timeout = 60

      base.superclass_delegating_accessor :max_retries
      base.max_retries = Connection::MAX_RETRIES

      base.superclass_delegating_accessor :logger
      base.superclass_delegating_accessor :wiredump_device

      base.superclass_delegating_accessor :proxy_address
      base.superclass_delegating_accessor :proxy_port
    end

    def raw_ssl_request(method, endpoint, data, headers = {})
      logger.warn "#{self.class} using ssl_strict=false, which is insecure" if logger unless ssl_strict

      connection = new_connection(endpoint)
      connection.open_timeout = open_timeout
      connection.read_timeout = read_timeout
      connection.retry_safe   = retry_safe
      connection.verify_peer  = ssl_strict
      connection.ssl_version  = ssl_version
      connection.logger       = logger
      connection.max_retries  = max_retries
      connection.tag          = self.class.name
      connection.wiredump_device = wiredump_device

      connection.pem          = @options[:pem] if @options
      connection.pem_password = @options[:pem_password] if @options

      connection.ignore_http_status = @options[:ignore_http_status] if @options

      connection.proxy_address = proxy_address
      connection.proxy_port = proxy_port

      connection.request(method, data, headers)
    end
  end
end
