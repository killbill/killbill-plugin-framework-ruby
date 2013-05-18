
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Model

      class ObjectType

        @@admissible_values  = [:ACCOUNT, :ACCOUNT_EMAIL, :BLOCKING_STATES, :BUNDLE, :CUSTOM_FIELD, :INVOICE, :PAYMENT, :INVOICE_ITEM, :INVOICE_PAYMENT, :SUBSCRIPTION, :SUBSCRIPTION_EVENT, :PAYMENT_ATTEMPT, :PAYMENT_METHOD, :REFUND, :TAG, :TAG_DEFINITION, :TENANT, :TENANT_KVS]
        attr_reader :enum

        def initialize(value)
          raise ArgumentError.new("Enum ObjectType does not have such value : #{value}") if ! ObjectType.is_admissible_value?(value)
          @enum = value
        end

        def ==(other)
          return false if other.nil?
          self.enum == other.enum
        end

        def self.is_admissible_value?(value)
          @@admissible_values.include?(value)
        end

        def self.admissible_values 
          @@admissible_values
        end
      end
    end
  end
end
