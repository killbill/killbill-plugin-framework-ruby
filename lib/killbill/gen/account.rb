
#
# TODO STEPH Should have been generated--- but not yet
#
module Killbill
  module Plugin
    module Gen

      class Account < AccountData

        attr_reader :id

        def initialize(id, external_key, name, first_name_length, email, bill_cycle_day_local, currency, payment_method_id, time_zone, locale, address1, address2, company_name, city, state_or_province, postal_code, country, phone, is_migrated, is_notified_for_invoices)
          super(external_key, name, first_name_length, email, bill_cycle_day_local, currency, payment_method_id, time_zone, locale, address1, address2, company_name, city, state_or_province, postal_code, country, phone, is_migrated, is_notified_for_invoices)
          @id = id
        end
      end
    end
  end
end

