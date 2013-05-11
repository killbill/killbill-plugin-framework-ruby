
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Gen

      class CustomField

        attr_reader :object_id, :object_type, :field_name, :field_value

        def initialize(object_id, object_type, field_name, field_value)
          @object_id = object_id
          @object_type = object_type
          @field_name = field_name
          @field_value = field_value
        end
      end
    end
  end
end
