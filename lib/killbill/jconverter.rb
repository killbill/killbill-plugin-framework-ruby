
require 'date'

module Killbill
  module Plugin

    class JConverter

      class << self

        #
        # Convert from ruby -> java
        #
        def to_account(data)
          Killbill::Plugin::Model::Account.new(to_uuid(data.id),
                                                  nil,
                                                  to_joda_date_time(data.created_date),
                                                  to_joda_date_time(data.updated_date),
                                                  to_string(data.external_key),
                                                  to_string(data.name),
                                                  data.first_name_length,
                                                  to_string(data.email),
                                                  data.bill_cycle_day_local,
                                                  to_currency(data.currency),
                                                  to_uuid(data.payment_method_id),
                                                  to_date_time_zone(data.time_zone),
                                                  to_string(data.locale),
                                                  to_string(data.address1),
                                                  to_string(data.address2),
                                                  to_string(data.company_name),
                                                  to_string(data.city),
                                                  to_string(data.state_or_province),
                                                  to_string(data.postal_code),
                                                  to_string(data.country),
                                                  to_string(data.phone),
                                                  to_boolean(data.is_migrated),
                                                  to_boolean(data.is_notified_for_invoices))
        end


        def to_account_data(data)
          Killbill::Plugin::Model::AccountData.new(to_string(data.external_key),
                                                 to_string(data.name),
                                                 data.first_name_length,
                                                 to_string(data.email),
                                                 data.bill_cycle_day_local,
                                                 to_currency(data.currency),
                                                 to_uuid(data.payment_method_id),
                                                 to_date_time_zone(data.time_zone),
                                                 to_string(data.locale),
                                                 to_string(data.address1),
                                                 to_string(data.address2),
                                                 to_string(data.company_name),
                                                 to_string(data.city),
                                                 to_string(data.state_or_province),
                                                 to_string(data.postal_code),
                                                 to_string(data.country),
                                                 to_string(data.phone),
                                                 to_boolean(data.is_migrated),
                                                 to_boolean(data.is_notified_for_invoices))
        end

        def to_payment_info_plugin(payment_response)
          Killbill::Plugin::Model::PaymentInfoPlugin.new(to_big_decimal_with_cents_conversion(payment_response.amount),
                                                       to_joda_date_time(payment_response.created_date),
                                                       to_joda_date_time(payment_response.effective_date),
                                                       to_payment_plugin_status(payment_response.status),
                                                       to_string(payment_response.gateway_error),
                                                       to_string(payment_response.gateway_error_code),
                                                       to_string(payment_response.first_payment_reference_id),
                                                       to_string(payment_response.second_payment_reference_id))
        end

        def to_refund_info_plugin(refund_response)
          Killbill::Plugin::Model::RefundInfoPlugin.new(to_big_decimal_with_cents_conversion(refund_response.amount),
                                                      to_joda_date_time(refund_response.created_date),
                                                      to_joda_date_time(refund_response.effective_date),
                                                      to_refund_plugin_status(refund_response.status),
                                                      to_string(refund_response.gateway_error),
                                                      to_string(refund_response.gateway_error_code),
                                                      to_string(refund_response.reference_id))
        end

        def to_payment_method_response(pm)
          props = java.util.ArrayList.new
          pm.properties.each do |p|
            jp = Killbill::Plugin::Model::PaymentMethodKVInfo.new(p.is_updatable, p.key, p.value)
            props.add(jp)
          end
          Killbill::Plugin::Model::PaymentMethodPlugin.new(to_string(pm.external_payment_method_id),
                                                         to_boolean(pm.is_default_payment_method),
                                                         props,
                                                         nil,
                                                         to_string(pm.type),
                                                         to_string(pm.cc_name),
                                                         to_string(pm.cc_type),
                                                         to_string(pm.cc_expiration_month),
                                                         to_string(pm.cc_expiration_year),
                                                         to_string(pm.cc_last4),
                                                         to_string(pm.address1),
                                                         to_string(pm.address2),
                                                         to_string(pm.city),
                                                         to_string(pm.state),
                                                         to_string(pm.zip),
                                                         to_string(pm.country))
        end

        def to_payment_method_info_plugin(pm)
          Killbill::Plugin::Model::PaymentMethodInfoPlugin.new(to_uuid(pm.account_id),
                                                             to_uuid(pm.payment_method_id),
                                                             to_boolean(pm.is_default),
                                                             to_string(pm.external_payment_method_id))
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


        def to_currency(currency)
          if currency.nil?
            return nil
          end
          if currency.enum == :GBP
             return Java::com.ning.billing.catalog.api.Currency::GBP
          elsif currency.enum == :MXN
            return Java::com.ning.billing.catalog.api.Currency::MXN
          elsif currency.enum == :BRL
              return Java::com.ning.billing.catalog.api.Currency::BRL
          elsif currency.enum == :EUR
              return Java::com.ning.billing.catalog.api.Currency::EUR
          elsif currency.enum == :AUD
              return Java::com.ning.billing.catalog.api.Currency::AUD
          elsif currency.enum == :USD
              return Java::com.ning.billing.catalog.api.Currency::USD
          end
          nil
        end


        def to_date_time_zone(date_time_zone)
          if date_time_zone.nil?
            return nil
          end
          if date_time_zone.enum == :UTC
            return org.joda.time.DateTimeZone::UTC
          end
          nil
        end


        def to_payment_plugin_status(status)
          if status.enum == :PROCESSED
            Java::com.ning.billing.payment.plugin.api.PaymentPluginStatus::PROCESSED
          elsif status.enum == :ERROR
            Java::com.ning.billing.payment.plugin.api.PaymentPluginStatus::ERROR
          else
            Java::com.ning.billing.payment.plugin.api.PaymentPluginStatus::UNDEFINED
          end
        end

        def to_refund_plugin_status(status)
          if status.enum == :PROCESSED
            Java::com.ning.billing.payment.plugin.api.RefundPluginStatus::PROCESSED
          elsif status.enum == :ERROR
            Java::com.ning.billing.payment.plugin.api.RefundPluginStatus::ERROR
          else
            Java::com.ning.billing.payment.plugin.api.RefundPluginStatus::UNDEFINED
          end
        end

        def to_object_type(type)
          if type.enum == :ACCOUNT
            Java::com.ning.billing.ObjectType::ACCOUNT
          elsif type.enum == :ACCOUNT_EMAIL
            Java::com.ning.billing.ObjectType::ACCOUNT_EMAIL
          elsif type.enum == :BLOCKING_STATES
            Java::com.ning.billing.ObjectType::BLOCKING_STATES
          elsif type.enum == :BUNDLE
            Java::com.ning.billing.ObjectType::BUNDLE
          elsif type.enum == :CUSTOM_FIELD
            Java::com.ning.billing.ObjectType::CUSTOM_FIELD
          elsif type.enum == :INVOICE
            Java::com.ning.billing.ObjectType::INVOICE
          elsif type.enum == :PAYMENT
            Java::com.ning.billing.ObjectType::PAYMENT
          elsif type.enum == :INVOICE_ITEM
            Java::com.ning.billing.ObjectType::INVOICE_ITEM
          elsif type.enum == :INVOICE_PAYMENT
            Java::com.ning.billing.ObjectType::INVOICE_PAYMENT
          elsif type.enum == :SUBSCRIPTION
            Java::com.ning.billing.ObjectType::SUBSCRIPTION
          elsif type.enum == :SUBSCRIPTION_EVENT
            Java::com.ning.billing.ObjectType::SUBSCRIPTION_EVENT
          elsif type.enum == :PAYMENT_ATTEMPT
            Java::com.ning.billing.ObjectType::PAYMENT_ATTEMPT
          elsif type.enum == :PAYMENT_METHOD
            Java::com.ning.billing.ObjectType::PAYMENT_METHOD
          elsif type.enum == :REFUND
            Java::com.ning.billing.ObjectType::REFUND
          elsif type.enum == :TAG
            Java::com.ning.billing.ObjectType::TAG
          elsif type.enum == :TAG_DEFINITION
            Java::com.ning.billing.ObjectType::TAG_DEFINITION
          elsif type.enum == :TENANT
            Java::com.ning.billing.ObjectType::TENANT
          else # type.enum == :TENANT_KVS
            Java::com.ning.billing.ObjectType::TENANT_KVS
          end
        end

        def to_big_decimal_with_cents_conversion(amount_in_cents)
          amount_in_cents.nil? ? java.math.BigDecimal::ZERO : java.math.BigDecimal.new('%.2f' % (amount_in_cents.to_i/100.0))
        end

        def to_boolean(b)
          b.nil? ? java.lang.Boolean.new(false) : java.lang.Boolean.new(b)
        end


        #
        # Convert from java -> ruby
        #


        def from_account(data)
          Killbill::Plugin::Model::Account.new(from_uuid(data.id),
                                            nil,
                                            #from_blocking_state(data.blocking_state),
                                            from_joda_date_time(data.created_date),
                                            from_joda_date_time(data.updated_date),
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

        def from_tag_definition(data)
          Killbill::Plugin::Model::TagDefinition.new(from_uuid(data.id),
                                                    from_joda_date_time(data.created_date),
                                                    from_joda_date_time(data.updated_date),
                                                    from_string(data.name),
                                                    from_string(data.description),
                                                    from_boolean(data.is_control_tag),
                                                    nil)
        end

        def from_blocking_state(data)
          if data.nil?
            return nil
          end
        end


        def from_tenant_context(context)
          return Killbill::Plugin::Model::TenantContext.new(from_uuid(context.tenant_id))
        end

        def from_call_context(context)
          return Killbill::Plugin::Model::CallContext.new(from_uuid(context.tenant_id),
                                                      from_uuid(context.user_token),
                                                      from_string(context.user_name),
                                                      from_call_origin(context.call_origin),
                                                      from_user_type(context.user_type),
                                                      from_string(context.reason_code),
                                                      from_string(context.comments),
                                                      from_joda_date_time(context.created_date),
                                                      from_joda_date_time(context.updated_date))
        end


        def from_uuid(uuid)
           uuid.nil? ? nil : Killbill::Plugin::Model::UUID.new(uuid.to_s)
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


        def from_currency(currency)
           if currency.nil?
             return nil
           end
           if currency.to_s == Java::com.ning.billing.catalog.api.Currency::GBP.to_s
              return Killbill::Plugin::Model::Currency.new(:GBP)
           elsif currency.to_s == Java::com.ning.billing.catalog.api.Currency::MXN.to_s
             return Killbill::Plugin::Model::Currency.new(:MXN)
           elsif currency.to_s == Java::com.ning.billing.catalog.api.Currency::BRL.to_s
               return Killbill::Plugin::Model::Currency.new(:BRL)
           elsif currency.to_s == Java::com.ning.billing.catalog.api.Currency::EUR.to_s
               return Killbill::Plugin::Model::Currency.new(:EUR)
           elsif currency.to_s == Java::com.ning.billing.catalog.api.Currency::AUD.to_s
               return Killbill::Plugin::Model::Currency.new(:AUD)
           elsif currency.to_s == Java::com.ning.billing.catalog.api.Currency::USD.to_s
               return Killbill::Plugin::Model::Currency.new(:USD)
           end
           nil
         end

         def from_call_origin(origin)
           if origin.nil?
             return nil
           end

           if origin.to_s  == Java::com.ning.billing.util.callcontext.CallOrigin::INTERNAL.to_s
             return Killbill::Plugin::Model::CallOrigin.new(:INTERNAL)
           elsif origin.to_s  == Java::com.ning.billing.util.callcontext.CallOrigin::EXTERNAL.to_s
             return Killbill::Plugin::Model::CallOrigin.new(:EXTERNAL)
           else
             return Killbill::Plugin::Model::CallOrigin.new(:TEST)
           end
         end

         def from_user_type(user)
           if user.nil?
             return nil
           end

           if user.to_s  == Java::com.ning.billing.util.callcontext.UserType::SYSTEM.to_s
             return Killbill::Plugin::Model::UserType.new(:SYSTEM)
           elsif user.to_s  == Java::com.ning.billing.util.callcontext.UserType::ADMIN.to_s
             return Killbill::Plugin::Model::UserType.new(:ADMIN)
           elsif user.to_s  == Java::com.ning.billing.util.callcontext.UserType::CUSTOMER.to_s
             return Killbill::Plugin::Model::UserType.new(:CUSTOMER)
           elsif user.to_s  == Java::com.ning.billing.util.callcontext.UserType::MIGRATION.to_s
             return Killbill::Plugin::Model::UserType.new(:MIGRATION)
           else # user == Java::com.ning.billing.util.callcontext.UserType::TEST
             return Killbill::Plugin::Model::UserType.new(:TEST)
           end
         end

         def from_date_time_zone(date_time_zone)
           if date_time_zone.nil?
             return nil
           end
           if date_time_zone.to_s == org.joda.time.DateTimeZone::UTC.to_s
             return Killbill::Plugin::Model::DateTimeZone.new(:UTC)
           end
           nil
         end


         def from_payment_plugin_status(status)
           if status.to_s == Java::com.ning.billing.payment.plugin.api.PaymentPluginStatus::PROCESSED.to_s
             Killbill::Plugin::Model::PaymentPluginStatus.new(:PROCESSED)
           elsif status.to_s == Java::com.ning.billing.payment.plugin.api.PaymentPluginStatus::ERROR.to_s
             Killbill::Plugin::Model::PaymentPluginStatus.new(:ERROR)
           else
             Killbill::Plugin::Model::PaymentPluginStatus.new(:UNDEFINED)
           end
         end

         def from_refund_plugin_status(status)
           if status.to_s  == Java::com.ning.billing.payment.plugin.api.RefundPluginStatus::PROCESSED.to_s
             Killbill::Plugin::Model::RefundPluginStatus.new(:PROCESSED)
           elsif status.to_s  == Java::com.ning.billing.payment.plugin.api.RefundPluginStatus::ERROR.to_s
             Killbill::Plugin::Model::RefundPluginStatus.new(:ERROR)
           else
             Killbill::Plugin::Model::RefundPluginStatus.new(:UNDEFINED)
           end
         end

         def from_big_decimal_with_cents_conversion(big_decimal)
           big_decimal.nil? ? 0 : big_decimal.multiply(java.math.BigDecimal.valueOf(100)).to_s.to_i
         end

         def from_boolean(b)
           if b.nil?
             return false
           end

           b_value = (b.java_kind_of? java.lang.Boolean) ? b.boolean_value : b
           return b_value ? true : false
         end

         def from_payment_method_plugin(pm)
           props = Array.new
           pm.properties.each do |p|
             key = from_string(p.key)
             value = from_string(p.value)
             is_updatable = from_boolean(p.is_updatable)
             props << Killbill::Plugin::Model::PaymentMethodKVInfo.new(is_updatable, key, value)
           end

           pmid = from_string(pm.external_payment_method_id)
           default = from_boolean(pm.is_default_payment_method)
           Killbill::Plugin::Model::PaymentMethodPlugin.new(from_string(pm.external_payment_method_id),
                                                          from_boolean(pm.is_default_payment_method),
                                                          props,
                                                          nil,
                                                          from_string(pm.type),
                                                          from_string(pm.cc_name),
                                                          from_string(pm.cc_type),
                                                          from_string(pm.cc_expiration_month),
                                                          from_string(pm.cc_expiration_year),
                                                          from_string(pm.cc_last4),
                                                          from_string(pm.address1),
                                                          from_string(pm.address2),
                                                          from_string(pm.city),
                                                          from_string(pm.state),
                                                          from_string(pm.zip),
                                                          from_string(pm.country))
         end

         def from_payment_method_info_plugin(pm)
           Killbill::Plugin::Model::PaymentMethodInfoPlugin.new(from_uuid(pm.account_id),
                                                              from_uuid(pm.payment_method_id),
                                                              from_boolean(pm.is_default),
                                                              from_string(pm.external_payment_method_id))
         end


         def from_ext_bus_event(event)
           Killbill::Plugin::Model::ExtBusEvent.new(from_bus_event_type(event.event_type),
                           from_object_type(event.object_type),
                           from_uuid(event.object_id),
                           from_uuid(event.account_id),
                           from_uuid(event.tenant_id))
         end

         def from_object_type(type)

           puts "from_object_type #{type.to_s}, type = #{type.inspect} #{Java::com.ning.billing.ObjectType::ACCOUNT.inspect} #{type.to_s == Java::com.ning.billing.ObjectType::ACCOUNT.to_s}"

           if type.to_s == Java::com.ning.billing.ObjectType::ACCOUNT.to_s
             Killbill::Plugin::Model::ObjectType.new(:ACCOUNT)
           elsif type.to_s == Java::com.ning.billing.ObjectType::ACCOUNT_EMAIL.to_s
               Killbill::Plugin::Model::ObjectType.new(:ACCOUNT_EMAIL)
           elsif  type.to_s == Java::com.ning.billing.ObjectType::BLOCKING_STATES.to_s
               Killbill::Plugin::Model::ObjectType.new(:BLOCKING_STATES)
           elsif type.to_s == Java::com.ning.billing.ObjectType::BUNDLE.to_s
               Killbill::Plugin::Model::ObjectType.new(:BUNDLE)
           elsif  type.to_s == Java::com.ning.billing.ObjectType::CUSTOM_FIELD.to_s
               Killbill::Plugin::Model::ObjectType.new(:CUSTOM_FIELD)
           elsif type.to_s == Java::com.ning.billing.ObjectType::INVOICE.to_s
               Killbill::Plugin::Model::ObjectType.new(:INVOICE)
           elsif  type.to_s == Java::com.ning.billing.ObjectType::PAYMENT.to_s
               Killbill::Plugin::Model::ObjectType.new(:PAYMENT)
           elsif type.to_s == Java::com.ning.billing.ObjectType::INVOICE_ITEM.to_s
               Killbill::Plugin::Model::ObjectType.new(:INVOICE_ITEM)
           elsif  type.to_s == Java::com.ning.billing.ObjectType::INVOICE_PAYMENT.to_s
               Killbill::Plugin::Model::ObjectType.new(:INVOICE_PAYMENT)
           elsif type.to_s == Java::com.ning.billing.ObjectType::SUBSCRIPTION.to_s
               Killbill::Plugin::Model::ObjectType.new(:SUBSCRIPTION)
           elsif  type.to_s == Java::com.ning.billing.ObjectType::SUBSCRIPTION_EVENT.to_s
               Killbill::Plugin::Model::ObjectType.new(:SUBSCRIPTION_EVENT)
           elsif type.to_s == Java::com.ning.billing.ObjectType::PAYMENT_ATTEMPT.to_s
               Killbill::Plugin::Model::ObjectType.new(:PAYMENT_ATTEMPT)
           elsif  type.to_s == Java::com.ning.billing.ObjectType::PAYMENT_METHOD.to_s
               Killbill::Plugin::Model::ObjectType.new(:PAYMENT_METHOD)
           elsif type.to_s == Java::com.ning.billing.ObjectType::REFUND.to_s
               Killbill::Plugin::Model::ObjectType.new(:REFUND)
           elsif type.to_s == Java::com.ning.billing.ObjectType::TAG.to_s
             Killbill::Plugin::Model::ObjectType.new(:TAG)
           elsif type.to_s == Java::com.ning.billing.ObjectType::TAG_DEFINITION.to_s
               Killbill::Plugin::Model::ObjectType.new(:TAG_DEFINITION)
           elsif  type.to_s == Java::com.ning.billing.ObjectType::TENANT.to_s
               Killbill::Plugin::Model::ObjectType.new(:TENANT)
           else
               Killbill::Plugin::Model::ObjectType.new(:TENANT_KVS)
           end
         end

        def from_bus_event_type(type)

          if type.to_s ==  Java::com.ning.billing.beatrix.bus.api.ExtBusEventType::ACCOUNT_CREATION.to_s
            Killbill::Plugin::Model::ExtBusEventType.new(:ACCOUNT_CREATION)
          elsif type.to_s ==  Java::com.ning.billing.beatrix.bus.api.ExtBusEventType::ACCOUNT_CHANGE.to_s
              Killbill::Plugin::Model::ExtBusEventType.new(:ACCOUNT_CHANGE)
          elsif  type.to_s ==  Java::com.ning.billing.beatrix.bus.api.ExtBusEventType::SUBSCRIPTION_CREATION.to_s
              Killbill::Plugin::Model::ExtBusEventType.new(:SUBSCRIPTION_CREATION)
          elsif type.to_s ==  Java::com.ning.billing.beatrix.bus.api.ExtBusEventType::SUBSCRIPTION_PHASE.to_s
              Killbill::Plugin::Model::ExtBusEventType.new(:SUBSCRIPTION_PHASE)
          elsif  type.to_s ==  Java::com.ning.billing.beatrix.bus.api.ExtBusEventType::SUBSCRIPTION_CHANGE.to_s
              Killbill::Plugin::Model::ExtBusEventType.new(:SUBSCRIPTION_CHANGE)
          elsif type.to_s ==  Java::com.ning.billing.beatrix.bus.api.ExtBusEventType::SUBSCRIPTION_CANCEL.to_s
              Killbill::Plugin::Model::ExtBusEventType.new(:SUBSCRIPTION_CANCEL)
          elsif  type.to_s ==  Java::com.ning.billing.beatrix.bus.api.ExtBusEventType::SUBSCRIPTION_UNCANCEL.to_s
              Killbill::Plugin::Model::ExtBusEventType.new(:SUBSCRIPTION_UNCANCEL)
          elsif type.to_s ==  Java::com.ning.billing.beatrix.bus.api.ExtBusEventType::OVERDUE_CHANGE.to_s
              Killbill::Plugin::Model::ExtBusEventType.new(:OVERDUE_CHANGE)
          elsif  type.to_s ==  Java::com.ning.billing.beatrix.bus.api.ExtBusEventType::INVOICE_CREATION.to_s
              Killbill::Plugin::Model::ExtBusEventType.new(:INVOICE_CREATION)
          elsif type.to_s ==  Java::com.ning.billing.beatrix.bus.api.ExtBusEventType::INVOICE_ADJUSTMENT.to_s
              Killbill::Plugin::Model::ExtBusEventType.new(:INVOICE_ADJUSTMENT)
          elsif  type.to_s ==  Java::com.ning.billing.beatrix.bus.api.ExtBusEventType::PAYMENT_SUCCESS.to_s
              Killbill::Plugin::Model::ExtBusEventType.new(:PAYMENT_SUCCESS)
          elsif type.to_s ==  Java::com.ning.billing.beatrix.bus.api.ExtBusEventType::PAYMENT_FAILED.to_s
              Killbill::Plugin::Model::ExtBusEventType.new(:PAYMENT_FAILED)
          elsif  type.to_s ==  Java::com.ning.billing.beatrix.bus.api.ExtBusEventType::TAG_CREATION.to_s
              Killbill::Plugin::Model::ExtBusEventType.new(:TAG_CREATION)
          elsif type.to_s ==  Java::com.ning.billing.beatrix.bus.api.ExtBusEventType::TAG_DELETION.to_s
              Killbill::Plugin::Model::ExtBusEventType.new(:TAG_DELETION)
          elsif type.to_s ==  Java::com.ning.billing.beatrix.bus.api.ExtBusEventType::CUSTOM_FIELD_CREATION.to_s
              Killbill::Plugin::Model::ExtBusEventType.new(:CUSTOM_FIELD_CREATION)
          else
              Killbill::Plugin::Model::ExtBusEventType.new(:CUSTOM_FIELD_DELETION)
          end
        end

      end
    end
  end
end
