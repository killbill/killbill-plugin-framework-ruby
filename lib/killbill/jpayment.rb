require 'singleton'

require 'killbill/plugin'
require 'killbill/jresponse/jpayment_response'
require 'killbill/jresponse/jrefund_response'
require 'killbill/jresponse/jpayment_method_response'
require 'killbill/jresponse/jpayment_method_response_internal'


module Killbill
  module Plugin

    # TODO fix package
    java_package 'com.ning.billing.osgi.api.http'
    class JPayment

      include Singleton

      include Java::com.ning.billing.payment.plugin.api.PaymentPluginApi

      def initialize(real_class_name, services = {})
        real_payment_class = Kernel.const_get(real_class_name)
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
          jpayment_response.new(payment_response)
        rescue Exception => e
          wrap_and_throw_exception(__methods__, e)
        end
      end

      java_signature 'Java::com.ning.billing.payment.plugin.api.PaymentInfoPlugin getPaymentInfo(java.util.UUID, Java::com.ning.billing.util.callcontext.TenantContext)'
      def get_payment_info(kb_payment_id, options = {})
        begin
          payment_response = @real_payment.get_payment_info(kb_payment_id, options)
          jpayment_response.new(payment_response)
        rescue Exception => e
          wrap_and_throw_exception(__methods__, e)
        end
      end

      java_signature 'Java::com.ning.billing.payment.plugin.api.RefundInfoPlugin processRefund(java.util.UUID, java.lang.BigDecimal, Java::com.ning.billing.util.callcontext.CallContext)'
      def refund(kb_payment_id, amount_in_cents, options = {})
        begin
          payment_refund = @real_payment.refund(kb_payment_id, amount_in_cents, options)
          jpayment_refund.new(payment_refund)
        rescue Exception => e
          wrap_and_throw_exception(__methods__, e)
        end
      end

      java_signature 'void addPaymentMethod(java.util.UUID, java.util.UUID, Java::com.ning.billing.payment.api.PaymentMethodPlugin, Java::boolean, Java::com.ning.billing.util.callcontext.CallContext)'
      def add_payment_method(kb_account_id, kb_payment_method_id, payment_method_props, set_default, options = {})
        begin
          payment_refund = @real_payment.add_payment_method(kb_account_id,kb_payment_method_id, payment_method_props, set_default)
          jpayment_refund.new(payment_refund)
        rescue Exception => e
          wrap_and_throw_exception(__methods__, e)
        end
      end

      java_signature 'void deletePaymentMethod(java.util.UUID, Java::com.ning.billing.util.callcontext.CallContext)'
      def delete_payment_method(kb_payment_method_id, options = {})
      end

      java_signature 'Java::com.ning.billing.payment.api.PaymentMethodPlugin getPaymentMethodDetail(java.util.UUID, java.util.UUID, Java::com.ning.billing.util.callcontext.TenantContext)'
      def get_payment_method_detail(kb_account_id, kb_payment_method_id, options = {})
      end

      java_signature 'void setDefaultPaymentMethod(java.util.UUID kbPaymentMethodId, Java::com.ning.billing.util.callcontext.CallContext)'
      def set_default_payment_method(kb_payment_method_id, options = {})
      end

      java_signature 'java.util.List getPaymentMethods(java.util.UUID, Java::boolean refreshFromGateway, Java::com.ning.billing.util.callcontext.CallContext)'
      def get_payment_methods(kb_account_id, options = {})
      end

      java_signature 'void resetPaymentMethods(java.util.List)'
      def reset_payment_methods(payment_methods)
      end

      private

      def wrap_and_throw_exception(api, e)
        raise Java::com.ning.billing.payment.plugin.api.PaymentPluginApiException.new("#{api} failure", e.message)
      end

    end
  end
end
