
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Gen

      class PaymentMethodPlugin

        attr_reader :external_payment_method_id, :is_default_payment_method, :properties, :value_string, :type, :cc_name, :cc_type, :cc_expiration_month, :cc_expiration_year, :cc_last4, :address1, :address2, :city, :state, :zip, :country

        def initialize(external_payment_method_id, is_default_payment_method, properties, value_string, type, cc_name, cc_type, cc_expiration_month, cc_expiration_year, cc_last4, address1, address2, city, state, zip, country)
          @external_payment_method_id = external_payment_method_id
          @is_default_payment_method = is_default_payment_method
          @properties = properties
          @value_string = value_string
          @type = type
          @cc_name = cc_name
          @cc_type = cc_type
          @cc_expiration_month = cc_expiration_month
          @cc_expiration_year = cc_expiration_year
          @cc_last4 = cc_last4
          @address1 = address1
          @address2 = address2
          @city = city
          @state = state
          @zip = zip
          @country = country
        end
      end
    end
  end
end
