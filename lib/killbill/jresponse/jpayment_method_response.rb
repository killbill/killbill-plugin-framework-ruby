require 'killbill/response/payment_method_response'
require 'killbill/jresponse/jconverter'

module Killbill
  module Plugin

    class JPaymentMethodProperty < Java::com.ning.billing.payment.api.PaymentMethodPlugin::PaymentMethodKVInfo

=begin
      attr_reader :key,
                  :value,
                  :is_updatable
=end

      class << self
        def create_from(payment_method_prop)

          key = JConverter.to_string(payment_method_prop.key)
          value = JConverter.to_string(payment_method_prop.value)
          is_updatable = JConverter.to_boolean(payment_method_prop.is_updatable)
=begin
          ctor = Java::com.ning.billing.payment.api.PaymentMethodPlugin::PaymentMethodKVInfo.java_class.constructor(java.lang.String, java.lang.Object, java.lang.Boolean)
          ctor.new_instance(key, value, is_updatable)
=end
          Java::com.ning.billing.payment.api.PaymentMethodPlugin::PaymentMethodKVInfo.new(key, value, is_updatable)
        end
      end
=begin
      java_signature 'java.lang.String getKey()'
      def get_key
        getKey()
      end

      java_signature 'java.lang.Object getValue()'
      def get_value
        value
      end

      java_signature 'java.lang.Boolean getIsUpdatable()'
      def is_updateable
        is_updateable
      end
=end
    end

    class JPaymentMethodResponse

      include Java::com.ning.billing.payment.api.PaymentMethodPlugin

      attr_reader :external_payment_method_id,
                   :is_default,
                   :properties

      def initialize(payment_method_response)
        @external_payment_method_id = JConverter.to_string(payment_method_response.external_payment_method_id)
        @is_default = JConverter.to_boolean(payment_method_response.is_default)
        @properties = java.util.ArrayList.new
        payment_method_response.properties.each do |p|
          jp = JPaymentMethodProperty.create_from(p)
          @properties.add(jp)
        end
      end

      java_signature 'java.lang.String getExternalPaymentMethodId()'
      def get_external_payment_method_id
        @external_payment_method_id
      end

      java_signature 'java.lang.Boolean isDefaultPaymentMethod()'
      def is_default_payment_method
        @is_default
      end

      java_signature 'java.util.List getProperties()'
      def get_properties
        @properties
      end

      java_signature 'java.lang.String getValueString(java.lang.String)'
      def get_value_string(key)
        @properties.each do |p|
          if p.key == key
            return p
          end
        end
        nil
      end
    end

  end
end
