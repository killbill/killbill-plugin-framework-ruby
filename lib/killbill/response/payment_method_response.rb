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
