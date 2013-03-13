
require 'killbill/response/payment_status'

module Killbill
  module Plugin

    class JConverter

      class << self

        def to_uuid(uuid)
          uuid.nil? ? nil : java.util.UUID.fromString(uuid.to_s)
        end

        def to_joda_date_time(time)
          time.nil? ? nil : org.joda.time.DateTime.new(time.to_s)
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

        def to_big_decimal(price)
          price.nil? ? java.math.BigDecimal::ZERO : java.math.BigDecimal.new(price.to_s)
        end

        def to_boolean(b)
          java.lang.Boolean.new(b)
        end

      end
    end
  end
end