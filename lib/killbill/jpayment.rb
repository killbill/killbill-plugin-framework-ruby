require 'singleton'

require 'killbill/plugin'
require 'killbill/jresponse/jpayment_response'
require 'killbill/jresponse/jrefund_response'
require 'killbill/jresponse/jpayment_method_response'
require 'killbill/jresponse/jpayment_method_response_internal'


module Killbill
  module Plugin

    java_package 'com.ning.billing.payment.plugin.api'
    class JPayment

      include Java::com.ning.billing.payment.plugin.api.PaymentPluginApi

      attr_reader :real_payment
      
      def initialize(real_class_name, services = {})
        real_payment_class = class_from_string(real_class_name)
        @real_payment = real_payment_class.new(services)
      end

      # TODO STEPH decide what to do the getName()
      java_signature 'java.lang.String getName()'
      def get_name
      end

      java_signature 'Java::com.ning.billing.payment.plugin.api.PaymentInfoPlugin processPayment(java.util.UUID, java.util.UUID, java.lang.BigDecimal, Java::com.ning.billing.util.callcontext.CallContext)'
      def charge(*args)
        begin
          payment_response = @real_payment.charge(*args)
          JPaymentResponse.new(payment_response)
        rescue Exception => e
          wrap_and_throw_exception(__method__, e)
        end
      end

      java_signature 'Java::com.ning.billing.payment.plugin.api.PaymentInfoPlugin getPaymentInfo(java.util.UUID, Java::com.ning.billing.util.callcontext.TenantContext)'
      def get_payment_info(*args)
        begin
          payment_response = @real_payment.get_payment_info(*args)
          JPaymentResponse.new(payment_response)
        rescue Exception => e
          wrap_and_throw_exception(__method__, e)
        end
      end

      java_signature 'Java::com.ning.billing.payment.plugin.api.RefundInfoPlugin processRefund(java.util.UUID, java.lang.BigDecimal, Java::com.ning.billing.util.callcontext.CallContext)'
      def refund(*args)
        begin
          payment_refund = @real_payment.refund(*args)
          JRefundResponse.new(payment_refund)
        rescue Exception => e
          wrap_and_throw_exception(__method__, e)
        end
      end

      java_signature 'void addPaymentMethod(java.util.UUID, java.util.UUID, Java::com.ning.billing.payment.api.PaymentMethodPlugin, Java::boolean, Java::com.ning.billing.util.callcontext.CallContext)'
      def add_payment_method(*args)
        begin
          payment_refund = @real_payment.add_payment_method(*args)
        rescue Exception => e
          wrap_and_throw_exception(__method__, e)
        end
      end

      java_signature 'void deletePaymentMethod(java.util.UUID, Java::com.ning.billing.util.callcontext.CallContext)'
      def delete_payment_method(*args)
        begin
          @real_payment.delete_payment_method(*args)
        rescue Exception => e
          wrap_and_throw_exception(__method__, e)
        end
      end

      java_signature 'Java::com.ning.billing.payment.api.PaymentMethodPlugin getPaymentMethodDetail(java.util.UUID, java.util.UUID, Java::com.ning.billing.util.callcontext.TenantContext)'
      def get_payment_method_detail(*args)
        begin
          payment_method_detail = @real_payment.get_payment_method_detail(*args)
          JPaymentMethodResponse.new(payment_method_detail)
        rescue Exception => e
          wrap_and_throw_exception(__method__, e)
        end
      end

      java_signature 'void setDefaultPaymentMethod(java.util.UUID kbPaymentMethodId, Java::com.ning.billing.util.callcontext.CallContext)'
      def set_default_payment_method(*args)
        begin
          @real_payment.set_default_payment_method(*args)
        rescue Exception => e
          wrap_and_throw_exception(__method__, e)
        end
      end

      java_signature 'java.util.List getPaymentMethods(java.util.UUID, Java::boolean refreshFromGateway, Java::com.ning.billing.util.callcontext.CallContext)'
      def get_payment_methods(*args)
        begin
          payment_methods = @real_payment.get_payment_methods(*args)
          res = java.util.ArrayList.new
          payment_methods.each do |pm|
            res.add(JPaymentMethodResponseInternal.new(pm))
          end
          res
        rescue Exception => e
          wrap_and_throw_exception(__method__, e)
        end
      end

      java_signature 'void resetPaymentMethods(java.util.List)'
      def reset_payment_methods(*args)
        begin
          @real_payment.reset_payment_methods(*args)
        rescue Exception => e
          wrap_and_throw_exception(__method__, e)
        end
      end

      private

      def wrap_and_throw_exception(api, e)
        raise Java::com.ning.billing.payment.plugin.api.PaymentPluginApiException.new("#{api} failure", e.message)
      end

      def class_from_string(str)
        str.split('::').inject(Kernel) do |mod, class_name|
          mod.const_get(class_name)
        end
      end

    end
  end
end
