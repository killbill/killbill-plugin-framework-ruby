
module Killbill
  module Plugin
    class Creator

      attr_reader :target_class_name

      def initialize(target_class_name)
        @target_class_name = target_class_name
      end

      def create(*args)
         real_class = class_from_string
          args.nil? ? real_class.new : real_class.new(*args)
      end

      private

      def class_from_string()
        @target_class_name.split('::').inject(Kernel) do |mod, class_name|
          mod.const_get(class_name)
        end
      end

    end
  end
end

