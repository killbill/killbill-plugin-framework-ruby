require 'killbill/response/payment_method_response_internal'
require 'killbill/jresponse/jconverter'

module Killbill
  module Plugin

    class JPaymentMethodResponseInternal

      include Java::com.ning.billing.payment.plugin.api.PaymentMethodInfoPlugin
      attr_reader :kb_account_id,
                   :kb_payment_method_id,
                   :is_default
                   :external_payment_method_id

      class << self
        def to_payment_method_response_internal(jinfo)
          account_id = JConverter.from_uuid(jinfo.get_account_id)
          payment_method_id = JConverter.from_uuid(jinfo.get_payment_method_id)
          is_default = JConverter.from_boolean(jinfo.is_default)
          external_payment_method_id = JConverter.from_string(jinfo.get_external_payment_method_id)
          PaymentMethodResponseInternal.new(account_id, payment_method_id, is_default, external_payment_method_id)
        end
      end

      def initialize(payment_method_response_internal)
        @kb_account_id = JConverter.to_uuid(payment_method_response_internal.kb_account_id)
        @kb_payment_method_id = JConverter.to_uuid(payment_method_response_internal.kb_payment_method_id)
        @is_default = JConverter.to_boolean(payment_method_response_internal.is_default)
        @external_payment_method_id = JConverter.to_string(payment_method_response_internal.external_payment_method_id)
      end

      java_signature 'java.lang.UUID getAccountId()'
      def get_account_id
        @kb_account_id
      end

      java_signature 'java.lang.UUID getPaymentMethodId()'
      def get_payment_method_id
        @kb_payment_method_id
      end

      java_signature 'java.lang.Boolean isDefault()'
      def is_default
        @is_default
      end

      java_signature 'java.lang.String getExternalPaymentMethodId()'
      def get_external_payment_method_id
        @external_payment_method_id
      end
    end
  end
end