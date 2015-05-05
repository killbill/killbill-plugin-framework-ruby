module Killbill
  module Plugin
    module PropertiesHelper

      def find_value_from_properties(properties, key = nil)
        return nil if key.nil?
        prop = (properties.find { |kv| kv.key.to_s == key.to_s })
        prop.nil? ? nil : prop.value
      end

      def hash_to_properties(options = {})
        merge_properties([], options)
      end

      def properties_to_hash(properties, options = {})
        merged = {}
        (properties || []).each do |p|
          merged[p.key.to_sym] = p.value
        end
        merged.merge(options)
      end

      def merge_properties(properties, options = {})
        merged = properties_to_hash(properties, options)

        properties = []
        merged.each do |k, v|
          properties << build_property(k, v)
        end
        properties
      end

      def build_property(key, value = nil)
        prop = ::Killbill::Plugin::Model::PluginProperty.new
        prop.key = key
        prop.value = value
        prop
      end
    end
  end
end
