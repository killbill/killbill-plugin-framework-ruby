
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Gen

      class TagDefinition

        attr_reader :id, :created_date, :updated_date, :name, :description, :is_control_tag

        def initialize(id, created_date, updated_date, name, description, is_control_tag)
          @id = id
          @created_date = created_date
          @updated_date = updated_date
          @name = name
          @description = description
          @is_control_tag = is_control_tag
        end
      end
    end
  end
end
