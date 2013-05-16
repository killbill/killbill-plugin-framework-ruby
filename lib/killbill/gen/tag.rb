
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Model

      class Tag

        include com.ning.billing.util.tag.Tag

        attr_reader :id, :created_date, :updated_date, :tag_definition_id, :object_type, :object_id

        def initialize(id, created_date, updated_date, tag_definition_id, object_type, object_id)
          @id = id
          @created_date = created_date
          @updated_date = updated_date
          @tag_definition_id = tag_definition_id
          @object_type = object_type
          @object_id = object_id
        end
      end
    end
  end
end
