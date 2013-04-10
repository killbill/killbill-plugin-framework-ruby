require 'killbill/response/refund_response'
require 'killbill/jresponse/jconverter'

module Killbill
  module Plugin

    java_package 'com.ning.billing.payment.plugin.api'
    class JRefundResponse

      include Java::com.ning.billing.payment.plugin.api.RefundInfoPlugin

      attr_reader :amount,
                  :created_date,
                  :effective_date,
                  :status,
                  :gateway_error,
                  :gateway_error_code,
                  :reference_id

      def initialize(refund_response)
        @amount = JConverter.to_big_decimal(refund_response.amount_in_cents)
        @created_date = JConverter.to_joda_date_time(refund_response.created_date)
        @effective_date = JConverter.to_joda_date_time(refund_response.effective_date)
        @status = JConverter.to_refund_plugin_status(refund_response.status)
        @gateway_error = JConverter.to_string(refund_response.gateway_error)
        @gateway_error_code = JConverter.to_string(refund_response.gateway_error_code)
        @reference_id = JConverter.to_string(refund_response.reference_id)
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

      java_signature 'java.lang.String getReferenceId()'
      def get_reference_id
        @reference_id
      end

   end
  end
end