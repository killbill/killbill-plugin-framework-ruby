# Plugin logger that will delegate to the OSGI LogService
module Killbill
  module Plugin
    class Logger
      def initialize(delegate)
        @logger = delegate
      end

      def debug(msg)
        @logger.log(4, msg)
      end

      def info(msg)
        @logger.log(3, msg)
      end

      def warn(msg)
        @logger.log(2, msg)
      end

      def error(msg)
        @logger.log(1, msg)
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
