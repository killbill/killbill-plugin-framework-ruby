
require 'date'
require 'killbill/response/payment_status'

module Killbill
  module Plugin

    class JConverter

      class << self

        #
        # Convert from ruby -> java
        #
        def to_uuid(uuid)
          uuid.nil? ? nil : java.util.UUID.fromString(uuid.to_s)
        end

        def to_joda_date_time(time)
          date_time = (time.kind_of? Time) ? DateTime.parse(time.to_s) : time
          date_time.nil? ? nil : org.joda.time.DateTime.new(date_time.to_s, org.joda.time.DateTimeZone::UTC)
        end

        def to_string(str)
          str.nil? ? nil : java.lang.String.new(str)
        end

        def to_payment_plugin_status(status)
          if status == PaymentStatus::SUCCESS
            Java::com.ning.billing.payment.plugin.api.PaymentInfoPlugin::PaymentPluginStatus::PROCESSED
          elsif status == PaymentStatus::ERROR
            Java::com.ning.billing.payment.plugin.api.PaymentInfoPlugin::PaymentPluginStatus::ERROR
          else
            Java::com.ning.billing.payment.plugin.api.PaymentInfoPlugin::PaymentPluginStatus::UNDEFINED
          end
        end

        def to_refund_plugin_status(status)
          if status == PaymentStatus::SUCCESS
            Java::com.ning.billing.payment.plugin.api.RefundInfoPlugin::RefundPluginStatus::PROCESSED
          elsif status == PaymentStatus::ERROR
            Java::com.ning.billing.payment.plugin.api.RefundInfoPlugin::RefundPluginStatus::ERROR
          else
            Java::com.ning.billing.payment.plugin.api.RefundInfoPlugin::RefundPluginStatus::UNDEFINED
          end
        end

        def to_big_decimal(amount_in_cents)
          amount_in_cents.nil? ? java.math.BigDecimal::ZERO : java.math.BigDecimal.new('%.2f' % (amount_in_cents.to_i/100.0))
        end

        def to_boolean(b)
          java.lang.Boolean.new(b)
        end


        #
        # Convert from java -> ruby
        #
        def from_uuid(uuid)
           uuid.nil? ? nil : uuid.to_s
        end

        def from_joda_date_time(joda_time)
          if joda_time.nil?
            return nil
          end

          fmt = org.joda.time.format.ISODateTimeFormat.date_time
          str = fmt.print(joda_time);
          DateTime.iso8601(str)
        end

        def from_string(str)
          str.nil? ? nil : str.to_s
        end

        def from_payment_plugin_status(status)
          if status == Java::com.ning.billing.payment.plugin.api.PaymentInfoPlugin::PaymentPluginStatus::PROCESSED
            PaymentStatus::SUCCESS
          elsif status == Java::com.ning.billing.payment.plugin.api.PaymentInfoPlugin::PaymentPluginStatus::ERROR
            PaymentStatus::ERROR
          else
            PaymentStatus::UNDEFINED
          end
        end

        def from_refund_plugin_status(status)
          if status == Java::com.ning.billing.payment.plugin.api.RefundInfoPlugin::RefundPluginStatus::PROCESSED
            PaymentStatus::SUCCESS
          elsif status == Java::com.ning.billing.payment.plugin.api.RefundInfoPlugin::RefundPluginStatus::ERROR
            PaymentStatus::ERROR
          else
            PaymentStatus::UNDEFINED
          end
        end

        def from_big_decimal(big_decimal)
          big_decimal.nil? ? 0 : big_decimal.multiply(java.math.BigDecimal.valueOf(100)).to_s.to_i
        end

        def from_boolean(b)
          if b.nil?
            return false
          end

          b_value = (b.java_kind_of? java.lang.Boolean) ? b.boolean_value : b
          return b_value ? true : false
        end

        def from_payment_method_plugin(payment_method_plugin)
          JPaymentMethodResponse.to_payment_method_response(payment_method_plugin)
        end

        def from_payment_method_info_plugin(payment_method_info_plugin)
         JPaymentMethodResponseInternal.to_payment_method_response_internal(payment_method_info_plugin)
        end
      end
    end
  end
end
