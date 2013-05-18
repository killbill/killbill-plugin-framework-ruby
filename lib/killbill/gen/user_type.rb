
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Model

      class UserType

        @@admissible_values  = [:SYSTEM, :ADMIN, :CUSTOMER, :MIGRATION, :TEST]
        attr_reader :enum

        def initialize(value)
          raise ArgumentError.new("Enum UserType does not have such value : #{value}") if ! UserType.is_admissible_value?(value)
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
