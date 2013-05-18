
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Model

      class ExtBusEventType

        @@admissible_values  = [:ACCOUNT_CREATION, :ACCOUNT_CHANGE, :SUBSCRIPTION_CREATION, :SUBSCRIPTION_PHASE, :SUBSCRIPTION_CHANGE, :SUBSCRIPTION_CANCEL, :SUBSCRIPTION_UNCANCEL, :OVERDUE_CHANGE, :INVOICE_CREATION, :INVOICE_ADJUSTMENT, :PAYMENT_SUCCESS, :PAYMENT_FAILED, :TAG_CREATION, :TAG_DELETION, :CUSTOM_FIELD_CREATION, :CUSTOM_FIELD_DELETION]
        attr_reader :enum

        def initialize(value)
          raise ArgumentError.new("Enum ExtBusEventType does not have such value : #{value}") if ! ExtBusEventType.is_admissible_value?(value)
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
