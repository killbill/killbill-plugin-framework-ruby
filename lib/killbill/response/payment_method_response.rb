module Killbill
  module Plugin

    class PaymentMethodProperty

      attr_reader :key,
                  :value,
                  :is_updatable

      def initialize(key, value, is_updatable)
        @key = key
        @value = value
        @is_updatable = is_updatable
      end
    end

    class PaymentMethodResponse

       PROP_TYPE = "type";
       PROP_CC_NAME = "cc_name";
       PROP_CC_TYPE = "cc_type";
       PROP_CC_EXP_MONTH = "cc_exp_month";
       PROP_CC_EXP_YEAR = "cc_exp_year";
       PROP_CC_LAST_4 = "cc_last_4";
       PROP_ADDRESS1 = "address1";
       PROP_ADDRESS2 = "address2";
       PROP_CITY = "city";
       PROP_STATE = "state";
       PROP_ZIP = "zip";
       PROP_COUNTRY = "country";

       attr_reader :external_payment_method_id,
                   :is_default,
                   :properties

       def initialize(external_payment_method_id, is_default, properties)
         @external_payment_method_id = external_payment_method_id
         @is_default = is_default
         @properties = properties
       end

       def value(key)
         (@properties || []).each do |prop|
           return prop.value if prop.key == key
         end
         nil
       end
    end
  end
end
