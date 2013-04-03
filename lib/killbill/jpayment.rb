require 'java'

require 'singleton'

require 'killbill/creator'
require 'killbill/plugin'
require 'killbill/jresponse/jpayment_response'
require 'killbill/jresponse/jrefund_response'
require 'killbill/jresponse/jpayment_method_response'
require 'killbill/jresponse/jpayment_method_response_internal'

include Java

class String
   def snake_case
     return downcase if match(/\A[A-Z]+\z/)
     gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
     gsub(/([a-z])([A-Z])/, '\1_\2').
     downcase
   end
end

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
          return JPaymentResponse.new(res)
        end
      end

      java_signature 'Java::com.ning.billing.payment.plugin.api.PaymentInfoPlugin getPaymentInfo(java.util.UUID, java.util.UUID, Java::com.ning.billing.util.callcontext.TenantContext)'
      def get_payment_info(*args)
        do_call_handle_exception(__method__, *args) do |res|
          return JPaymentResponse.new(res)
        end
      end

      java_signature 'Java::com.ning.billing.payment.plugin.api.RefundInfoPlugin processRefund(java.util.UUID, java.util.UUID, java.lang.BigDecimal, com.ning.billing.catalog.api.Currency, Java::com.ning.billing.util.callcontext.CallContext)'
      def process_refund(*args)
        do_call_handle_exception(__method__, *args) do |res|
          return JRefundResponse.new(res)
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
          return JPaymentMethodResponse.new(res)
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
            array_res.add(JPaymentMethodResponseInternal.new(el))
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

      private

      def do_call_handle_exception(method_name, *args)
        begin
          rargs = convert_args(method_name, args)
          res = @delegate_plugin.send(method_name.to_s.snake_case.to_sym, *rargs)
          yield(res)
        rescue Exception => e
          wrap_and_throw_exception(method_name, e)
        ensure
          @delegate_plugin.after_request
        end
      end

      def wrap_and_throw_exception(api, e)
        message = "#{api} failure: #{e}"
        unless e.backtrace.nil?
          message = "#{message}\n#{e.backtrace.join("\n")}"
        end
        logger.warn message
        raise Java::com.ning.billing.payment.plugin.api.PaymentPluginApiException.new("#{api} failure", e.message)
      end


      def convert_args(api, args)
        args.collect! do |a|
         if a.nil?
           nil
         elsif a.java_kind_of? java.util.UUID
           JConverter.from_uuid(a)
         elsif a.java_kind_of? java.math.BigDecimal
           JConverter.from_big_decimal(a)
         elsif a.java_kind_of? Java::com.ning.billing.catalog.api.Currency
           a.to_string
         elsif a.java_kind_of? Java::com.ning.billing.payment.api.PaymentMethodPlugin
           JConverter.from_payment_method_plugin(a)
         elsif ((a.java_kind_of? Java::boolean) || (a.java_kind_of? java.lang.Boolean))
           JConverter.from_boolean(a)
         # Require because it looks like if non boxed value are passed they already arrive as Ruby type
         elsif ((a.java_kind_of? TrueClass) || (a.java_kind_of? FalseClass))
           a
         elsif a.java_kind_of? java.util.List
           result = Array.new
           if a.size > 0
             first_element = a.get(0)
             if first_element.java_kind_of? Java::com.ning.billing.payment.plugin.api.PaymentMethodInfoPlugin
               a.each do |el|
                 result << JConverter.from_payment_method_info_plugin(el)
               end
             else
               raise Java::com.ning.billing.payment.plugin.api.PaymentPluginApiException.new("#{api} failure", "Unexpected parameter type #{first_element.class} for list")
             end
           end
           result
         else
           # Since we don't pass the Context at this point, we can't raise any exceptions for unexpected types.
           #raise Java::com.ning.billing.payment.plugin.api.PaymentPluginApiException.new("#{api} failure", "Unexpected parameter type #{a.class}")
           nil
         end
        end
        # Remove last argument if this is null (it means we passed a context)
        args.delete_at(-1) if args[-1].nil?
        args
      end

    end
  end
end
