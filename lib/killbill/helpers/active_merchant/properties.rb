require 'erb'
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
          @config = YAML.load(ERB.new(File.read(@config_file.to_s)).result)
        end

        def [](key)
          @config[key]
        end

        def to_hash
          @config.dup
        end
      end
    end
  end
end
