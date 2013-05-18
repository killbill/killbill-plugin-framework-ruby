
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Model

      class Currency

        @@admissible_values  = [:GBP, :MXN, :BRL, :EUR, :AUD, :USD]
        attr_reader :enum

        def initialize(value)
          raise ArgumentError.new("Enum Currency does not have such value : #{value}") if ! Currency.is_admissible_value?(value)
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
