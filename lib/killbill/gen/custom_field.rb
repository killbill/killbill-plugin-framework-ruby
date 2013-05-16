
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Model

      class CustomField

        include com.ning.billing.util.customfield.CustomField

        attr_reader :id, :created_date, :updated_date, :object_id, :object_type, :field_name, :field_value

        def initialize(id, created_date, updated_date, object_id, object_type, field_name, field_value)
          @id = id
          @created_date = created_date
          @updated_date = updated_date
          @object_id = object_id
          @object_type = object_type
          @field_name = field_name
          @field_value = field_value
        end
      end
    end
  end
end
