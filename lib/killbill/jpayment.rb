require 'java'

require 'singleton'

require 'killbill/creator'
require 'killbill/plugin'
require 'killbill/jconverter'

include Java


module Killbill
  module Plugin

    java_package 'com.ning.billing.payment.plugin.api'
    class JPayment < JPlugin

#      java_implements com.ning.billing.payment.plugin.api.PaymentPluginApi
      include com.ning.billing.payment.plugin.api.PaymentPluginApi

      def initialize(real_class_name, services = {})
        super(real_class_name, services)
      end

      java_signature 'com.ning.billing.payment.plugin.api.PaymentInfoPlugin processPayment(java.util.UUID, java.util.UUID, java.util.UUID, java.lang.BigDecimal, com.ning.billing.catalog.api.Currency, com.ning.billing.util.callcontext.CallContext)'
      def process_payment(*args)
        do_call_handle_exception(__method__, *args) do |res|
          return JConverter.to_payment_info_plugin(res)
        end
      end

      java_signature 'Java::com.ning.billing.payment.plugin.api.PaymentInfoPlugin getPaymentInfo(java.util.UUID, java.util.UUID, Java::com.ning.billing.util.callcontext.TenantContext)'
      def get_payment_info(*args)
        do_call_handle_exception(__method__, *args) do |res|
          return JConverter.to_payment_info_plugin(res)
        end
      end

      java_signature 'Java::com.ning.billing.payment.plugin.api.RefundInfoPlugin processRefund(java.util.UUID, java.util.UUID, java.lang.BigDecimal, com.ning.billing.catalog.api.Currency, Java::com.ning.billing.util.callcontext.CallContext)'
      def process_refund(*args)
        do_call_handle_exception(__method__, *args) do |res|
          return JConverter.to_refund_info_plugin(res)
        end
      end

      java_signature 'java.util.List  getRefundInfo(java.util.UUID, java.util.UUID, Java::com.ning.billing.util.callcontext.TenantContext)'
      def get_refund_info(*args)
        do_call_handle_exception(__method__, *args) do |res|
          array_res = java.util.ArrayList.new
          res.each do |el|
            array_res.add(JConverter.to_refund_info_plugin(el))
          end
          return array_res
        end
      end

      java_signature 'void addPaymentMethod(java.util.UUID, java.util.UUID, Java::com.ning.billing.payment.api.PaymentMethodPlugin, Java::boolean, Java::com.ning.billing.util.callcontext.CallContext)'
      def add_payment_method(*args)
        do_call_handle_exception(__method__, *args) do |res|
          return nil
        end
      end

      java_signature 'void deletePaymentMethod(java.util.UUID, java.util.UUID, Java::com.ning.billing.util.callcontext.CallContext)'
      def delete_payment_method(*args)
        do_call_handle_exception(__method__, *args) do |res|
          return nil
        end
      end

      java_signature 'Java::com.ning.billing.payment.api.PaymentMethodPlugin getPaymentMethodDetail(java.util.UUID, java.util.UUID, Java::com.ning.billing.util.callcontext.TenantContext)'
      def get_payment_method_detail(*args)
        do_call_handle_exception(__method__, *args) do |res|
          return JConverter.to_payment_method_response(res)
        end
      end

      java_signature 'void setDefaultPaymentMethod(java.util.UUID, java.util.UUID, Java::com.ning.billing.util.callcontext.CallContext)'
      def set_default_payment_method(*args)
        do_call_handle_exception(__method__, *args) do |res|
          return nil
        end
      end

      java_signature 'java.util.List getPaymentMethods(java.util.UUID, Java::boolean, Java::com.ning.billing.util.callcontext.CallContext)'
      def get_payment_methods(*args)
        do_call_handle_exception(__method__, *args) do |res|
          array_res = java.util.ArrayList.new
          res.each do |el|
            array_res.add(JConverter.to_payment_method_info_plugin(el))
          end
          return array_res
        end
      end

      java_signature 'void resetPaymentMethods(java.util.UUID, java.util.List)'
      def reset_payment_methods(*args)
        do_call_handle_exception(__method__, *args) do |res|
          return nil
        end
      end

    end
  end
end
