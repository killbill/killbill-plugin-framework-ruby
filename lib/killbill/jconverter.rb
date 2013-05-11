
require 'date'
require 'killbill/response/payment_status'

module Killbill
  module Plugin

    class JConverter

      class << self

        #
        # Convert from ruby -> java
        #
        def to_account_data(data)
          Killbill::Plugin::Gen::AccountData.new(data.external_key,
                                                 data.name,
                                                 data.first_name_length,
                                                 data.email,
                                                 data.bill_cycle_day_local,
                                                 to_currency(data.currency),
                                                 to_uuid(data.payment_method_id),
                                                 to_date_time_zone(data.time_zone),
                                                 data.locale,
                                                 data.address1,
                                                 data.address2,
                                                 data.company_name,
                                                 data.city,
                                                 data.state_or_province,
                                                 data.postal_code,
                                                 data.country,
                                                 data.phone,
                                                 data.is_migrated,
                                                 data.is_notified_for_invoices)
        end

        def to_currency(currency)
          if currency.nil?
            return nil
          end
          if currency == Killbill::Plugin::Gen::Currency::GBP
             return Java::com.ning.billing.catalog.api.Currency::GBP
          elsif currency == Killbill::Plugin::Gen::Currency::MXN
            return Java::com.ning.billing.catalog.api.Currency::MXN
          elsif currency == Killbill::Plugin::Gen::Currency::BRL
              return Java::com.ning.billing.catalog.api.Currency::BRL
          elsif currency == Killbill::Plugin::Gen::Currency::EUR
              return Java::com.ning.billing.catalog.api.Currency::EUR
          elsif currency == Killbill::Plugin::Gen::Currency::AUD
              return Java::com.ning.billing.catalog.api.Currency::AUD
          elsif currency == Killbill::Plugin::Gen::Currency::USD
              return Java::com.ning.billing.catalog.api.Currency::USD
          end
          nil
        end

        def to_date_time_zone(date_time_zone)
          if date_time_zone.nil?
            return nil
          end
          if date_time_zone == Killbill::Plugin::Gen::DateTimeZone::UTC
            return org.joda.time.DateTimeZone::UTC
          end
          nil
        end

        def to_uuid(uuid)
          uuid.nil? ? nil : java.util.UUID.fromString(uuid.to_s)
        end

        def to_joda_date_time(time)
          date_time = (time.kind_of? Time) ? DateTime.parse(time.to_s) : time
          date_time.nil? ? nil : org.joda.time.DateTime.new(date_time.to_s, org.joda.time.DateTimeZone::UTC)
        end

        def to_string(str)
          str.nil? ? nil : java.lang.String.new(str.to_s)
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


        def from_account(data)
          Killbill::Plugin::Gen::Account.new(from_uuid(data.id),
                                            from_string(data.external_key),
                                            from_string(data.name),
                                            data.first_name_length,
                                            from_string(data.email),
                                            data.bill_cycle_day_local,
                                            from_currency(data.currency),
                                            from_uuid(data.payment_method_id),
                                            from_date_time_zone(data.time_zone),
                                            from_string(data.locale),
                                            from_string(data.address1),
                                            from_string(data.address2),
                                            from_string(data.company_name),
                                            from_string(data.city),
                                            from_string(data.state_or_province),
                                            from_string(data.postal_code),
                                            from_string(data.country),
                                            from_string(data.phone),
                                            from_boolean(data.is_migrated),
                                            from_boolean(data.is_notified_for_invoices))

        end

        def from_currency(currency)
          if currency.nil?
            return nil
          end
          if currency == Java::com.ning.billing.catalog.api.Currency::GBP
             return Killbill::Plugin::Gen::Currency::GBP
          elsif currency == Java::com.ning.billing.catalog.api.Currency::MXN
            return Killbill::Plugin::Gen::Currency::MXN
          elsif currency == Java::com.ning.billing.catalog.api.Currency::BRL
              return Killbill::Plugin::Gen::Currency::BRL
          elsif currency == Java::com.ning.billing.catalog.api.Currency::EUR
              return Killbill::Plugin::Gen::Currency::EUR
          elsif currency == Java::com.ning.billing.catalog.api.Currency::AUD
              return Killbill::Plugin::Gen::Currency::AUD
          elsif currency == Java::com.ning.billing.catalog.api.Currency::USD
              return Killbill::Plugin::Gen::Currency::USD
          end
          nil
        end

        def from_date_time_zone(date_time_zone)
          if date_time_zone.nil?
            return nil
          end
          if date_time_zone == org.joda.time.DateTimeZone::UTC
            return Killbill::Plugin::Gen::DateTimeZone::UTC
          end
          nil
        end

        def from_uuid(uuid)
           uuid.nil? ? nil : Killbill::Plugin::Gen::UUID.new(uuid.to_s)
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

        def from_ext_bus_event(ext_bus)
          JEvent.to_event(ext_bus)
        end

      end
    end
  end
end
