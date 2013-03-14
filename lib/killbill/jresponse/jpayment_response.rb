require 'killbill/response/payment_response'
require 'killbill/jresponse/jconverter'

module Killbill
  module Plugin

    class JPaymentResponse

      include Java::com.ning.billing.payment.plugin.api.PaymentInfoPlugin

      attr_reader :amount,
                  :created_date,
                  :effective_date,
                  :status,
                  :gateway_error,
                  :gateway_error_code

      def initialize(payment_response)
        @amount = JConverter.to_big_decimal(payment_response.amount_in_cents)
        @created_date = JConverter.to_joda_date_time(payment_response.created_date)
        @effective_date = JConverter.to_joda_date_time(payment_response.effective_date)
        @status = JConverter.to_payment_plugin_status(payment_response.status)
        @gateway_error = JConverter.to_string(payment_response.gateway_error)
        @gateway_error_code = JConverter.to_string(payment_response.gateway_error_code)
      end

      java_signature 'java.math.BigDecimal getAmount()'
      def get_amount
        @amount
      end

      java_signature 'org.joda.time.DateTime getCreatedDate()'
      def get_created_date
        @created_date
      end

      java_signature 'org.joda.time.DateTime getEffectiveDate()'
      def get_effective_date
        @effective_date
      end

      java_signature 'Java::com.ning.billing.payment.plugin.api.PaymentInfoPlugin::PaymentPluginStatus getStatus()'
      def get_status
        @status
      end

      java_signature 'java.lang.String getGatewayError()'
      def get_gateway_error
        @gateway_error
      end

      java_signature 'java.lang.String getGatewayErrorCode()'
      def get_gateway_error_code
        @gateway_error_code
      end
    end
  end
end