
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Gen

      class Account

        attr_reader :id, :blocking_state, :created_date, :updated_date, :external_key, :name, :first_name_length, :email, :bill_cycle_day_local, :currency, :payment_method_id, :time_zone, :locale, :address1, :address2, :company_name, :city, :state_or_province, :postal_code, :country, :phone, :is_migrated, :is_notified_for_invoices

        def initialize(id, blocking_state, created_date, updated_date, external_key, name, first_name_length, email, bill_cycle_day_local, currency, payment_method_id, time_zone, locale, address1, address2, company_name, city, state_or_province, postal_code, country, phone, is_migrated, is_notified_for_invoices)
          @id = id
          @blocking_state = blocking_state
          @created_date = created_date
          @updated_date = updated_date
          @external_key = external_key
          @name = name
          @first_name_length = first_name_length
          @email = email
          @bill_cycle_day_local = bill_cycle_day_local
          @currency = currency
          @payment_method_id = payment_method_id
          @time_zone = time_zone
          @locale = locale
          @address1 = address1
          @address2 = address2
          @company_name = company_name
          @city = city
          @state_or_province = state_or_province
          @postal_code = postal_code
          @country = country
          @phone = phone
          @is_migrated = is_migrated
          @is_notified_for_invoices = is_notified_for_invoices
        end
      end
    end
  end
end
