require 'yaml'

module Killbill
  module Plugin
    module ActiveMerchant
      class Properties
        def initialize(file)
          @config_file = Pathname.new(file).expand_path
        end

        def parse!
          raise "#{@config_file} is not a valid file" unless @config_file.file?
          @config = YAML.load_file(@config_file.to_s)
        end

        def [](key)
          @config[key]
        end
      end
    end
  end
end