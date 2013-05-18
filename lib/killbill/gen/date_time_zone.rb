

#
# TODO STEPH Should have been generated--- but not yet
#
module Killbill
  module Plugin
    module Model

      class DateTimeZone
      
        @@admissible_values  = [:UTC]
        attr_reader :enum
      
        def initialize(value)
          raise ArgumentError.new("Enum DateTimeZone does not have such value : #{value}") if ! DateTimeZone.is_admissible_value?(value)
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
