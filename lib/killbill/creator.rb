require 'java'

require 'killbill/jkillbill_api'
require 'killbill/killbill_api'

include Java

module Killbill
  module Plugin
    class Creator

      attr_reader :target_class_name

      def initialize(target_class_name)
        @target_class_name = target_class_name
      end

      def create(services)
         japi_proxy = JKillbillApi.new(@target_class_name, services)

         kb_apis = KillbillApi.new(japi_proxy)
         real_class = class_from_string
         plugin_delegate = real_class.new
         plugin_delegate.root = services["root"]
         plugin_delegate.logger = services["logger"]
         plugin_delegate.conf_dir = services["conf_dir"]
         plugin_delegate.kb_apis = kb_apis
         plugin_delegate
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

