module Killbill
  module Plugin

    module Enum
    
      class NameValuePair
        attr_reader :label, :value
        
        def initialize(label, value)
          @label = label
          @value = value
        end
        
        def first
          @label
        end
        
        def last
          @value
        end
      end
      
      def const_missing(key)
        @enum_hash[key]
      end
      
      def add_enum(key, value)
        @enum_hash ||= {}
        @enum_hash[key] = NameValuePair.new(value, key.to_s)
      end
      
      def each
        @enum_hash.values.sort { |v1, v2| v1.label <=> v2.label }.each do |k|
          yield(k)
        end
      end
      
      def collect
        @enum_hash.values.sort { |v1, v2| v1.label <=> v2.label }.collect do |k|
          yield(k)
        end
      end
      
      def each_with_index
        @enum_hash.values.sort { |v1, v2| v1.label <=> v2.label }.each_with_index do |k, i|
          yield(k, i)
        end
      end
      
      def enums
        @enum_hash.keys
      end
      
      def enum_values
        @enum_hash.values
      end
      
      def get_enum_hash
        @enum_hash
      end
      
      def find_by_key(key)
        @enum_hash[key.upcase.to_sym]
      end
    
      def size
        @enum_hash.keys.size
      end
    end
  end
end
 
