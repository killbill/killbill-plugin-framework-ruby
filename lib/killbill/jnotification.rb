require 'java'

require 'singleton'

require 'killbill/creator'
require 'killbill/plugin'
require 'killbill/jresponse/jpayment_response'
require 'killbill/jresponse/jrefund_response'
require 'killbill/jresponse/jpayment_method_response'
require 'killbill/jresponse/jpayment_method_response_internal'

include Java

module Killbill
  module Plugin

    java_package 'com.ning.billing.notification.plugin.api'
    class JNotification < JPlugin

      include 'com.ning.billing.notification.plugin.api.NotificationPluginApi'

      def initialize(real_class_name, services = {})
        super(real_class_name, services)
      end

      java_signature 'void onEvent(Java::com.ning.billing.beatrix.bus.api.ExtBusEvent killbillEvent)'
      def on_event(killbill_event)
         do_call_handle_exception(__method__, *args) do |res|
            return nil
          end
      end

    end
  end
end
