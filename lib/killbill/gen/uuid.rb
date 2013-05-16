#
# TODO STEPH Should have been generated--- but not yet
#
module Killbill
  module Plugin
    module Model

      class UUID

        attr_reader :uuid

        def initialize(uuid)
          @uuid = uuid
        end

        def to_s
          @uuid.to_s
        end
      end
    end
  end
end
