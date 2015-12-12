require 'java'
require 'pathname'

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
        real_class = @target_class_name.to_class

        plugin_delegate = real_class.new
        plugin_delegate.root = services["root"]
        plugin_delegate.logger = services["logger"]
        plugin_delegate.conf_dir = services["conf_dir"]
        plugin_delegate.clock = services["clock"]

        plugin_delegate.plugin_name = extract_plugin_name(plugin_delegate.root)

        # At this point we removed everything from the map which is not API, so we can build the APIs
        # Note: services["kb_apis"] is never nil, except in tests
        kb_apis = KillbillApi.new(@target_class_name, services["kb_apis"] || {})
        plugin_delegate.kb_apis = kb_apis

        plugin_delegate
      end


      private

      def extract_plugin_name(root)
        p = Pathname.new(root)
        p.split[0].split[-1].to_s
      end

    end
  end
end

