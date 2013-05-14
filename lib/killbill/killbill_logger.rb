# Plugin logger that will delegate to the OSGI LogService
# Used for regular logging for plugins, as well as Rack logger and Error Stream
# Methods to implement for rack are described here: http://rack.rubyforge.org/doc/SPEC.html
module Killbill
  module Plugin
    class KillbillLogger
      def initialize(delegate)
        @logger = delegate
      end

      def debug(message, &block)
        @logger.log(4, build_message(message, &block))
      end

      def info(message, &block)
        @logger.log(3, build_message(message, &block))
      end

      def warn(message, &block)
        @logger.log(2, build_message(message, &block))
      end

      def error(message, &block)
        @logger.log(1, build_message(message, &block))
      end

      # Rack Error stream
      alias_method :puts, :warn
      alias_method :write, :warn

      def flush
      end

      def close
      end

      def build_message(message, &block)
        if message.nil?
          if block_given?
            message = yield
          else
            message = "(nil)"
          end
        end
        message.nil? ? "(nil)" : message.to_s
      end

      alias_method :fatal, :error

      # XXX TODO
      def debug?
        false
      end

      def info?
        true
      end

      def warn?
        true
      end

      alias_method :error?, :warn?
      alias_method :fatal?, :error?
    end
  end
end
