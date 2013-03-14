require 'killbill/response/payment_method_response'
require 'killbill/jresponse/jconverter'

module Killbill
  module Plugin

    class JPaymentMethodProperty < Java::com.ning.billing.payment.api.PaymentMethodPlugin::PaymentMethodKVInfo

      class << self
        def create_from(payment_method_prop)

          key = JConverter.to_string(payment_method_prop.key)
          value = JConverter.to_string(payment_method_prop.value)
          is_updatable = JConverter.to_boolean(payment_method_prop.is_updatable)
          Java::com.ning.billing.payment.api.PaymentMethodPlugin::PaymentMethodKVInfo.new(key, value, is_updatable)
        end
      
        def to_payment_method_property(jpayment_method_prop)
          key = JConverter.from_string(jpayment_method_prop.get_key)
          value = JConverter.from_string(jpayment_method_prop.get_value)
          is_updatable = JConverter.from_boolean(jpayment_method_prop.get_is_updatable)
          PaymentMethodProperty.new(key, value, is_updatable)
        end
      
      end
      
    end

    class JPaymentMethodResponse

      include Java::com.ning.billing.payment.api.PaymentMethodPlugin

      attr_reader :external_payment_method_id,
                   :is_default,
                   :properties
      
      class << self
        def to_payment_method_response(jpayment_method_response)
          props = Array.new
          jpayment_method_response.get_roperties.each do |p|
            props << JPaymentMethodProperty.to_payment_method_property(p)
          end
          pmid = JConverter.from_string(jpayment_method_response.get_external_payment_method_id)
          default = JConverter.from_boolean(jpayment_method_response.is_default_payment_method)
          PaymentMethodResponse.new(pmid, default, props)
        end
        
      end

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
