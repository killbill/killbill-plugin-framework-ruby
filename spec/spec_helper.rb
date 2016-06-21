require 'bundler'

require 'logger'
require 'tempfile'
require 'tmpdir'

require 'killbill'
require 'killbill/killbill_logger'
# JRuby specific, not required by default
require 'killbill/http_servlet'

require 'killbill/payment_test'
require 'killbill/notification_test'
require 'killbill/invoice_test'
require 'killbill/helpers/active_merchant'
require 'killbill/helpers/active_merchant/active_record/models/helpers'
require 'killbill/helpers/active_merchant/killbill_spec_helper'

require 'killbill/ext/active_merchant/typhoeus_connection'

require 'spec/killbill/helpers/test_payment_method'
require 'spec/killbill/helpers/test_response'
require 'spec/killbill/helpers/test_transaction'

if defined? JRUBY_VERSION
  require 'java'
  %w(
    MockAccountUserApi
  ).each do |api|
    begin
      java_import "org.killbill.billing.mock.api.#{api}"
    rescue LoadError => e
      puts e
    end
  end
end

require 'rspec'

module Killbill
  module Plugin
    module SpecHelper
      def with_plugin_yaml_config(file_name, plugin_config, include_db_config = true)
        if include_db_config
          plugin_config = plugin_config.dup
          plugin_config[:database] = database_config
        end
        Dir.mktmpdir do |dir|
          file = File.join(dir, file_name)
          File.open(file, 'w+') { |f| f.write plugin_config.to_yaml }
          yield file
        end
      end

      def database_config
        ActiveRecord::Base.connection_config.select do |key,_|
          [ :adapter, :database, :username, :password ].include? key
        end
      end

      def reinitialize_active_record
        require defined?(JRUBY_VERSION) ? 'arjdbc' : 'active_record'
        db_config = {
            :adapter => ENV['AR_ADAPTER'] || 'sqlite3',
            :database => ENV['AR_DATABASE'] || 'test.db',
        }
        db_config[:username] = ENV['AR_USERNAME'] if ENV['AR_USERNAME']
        db_config[:password] = ENV['AR_PASSWORD'] if ENV['AR_PASSWORD']
        ActiveRecord::Base.establish_connection(db_config)

        # For debugging
        ActiveRecord::Base.logger = Logger.new(STDOUT)
        ActiveRecord::Base.logger.level =
            if level = ENV['LOG_LEVEL']
              level.to_i.to_s == level ? level.to_i : Logger.const_get(level.upcase)
            else
              Logger::INFO
            end
        # Create the schema
        require File.expand_path(File.dirname(__FILE__) + '/killbill/helpers/test_schema.rb')

        # Required to have MySQL store milliseconds
        Time::DATE_FORMATS.merge!({ db: '%Y-%m-%d %H:%M:%S.%3N' }) if %w(mariadb mysql).include?(ENV['AR_ADAPTER'])
      end
    end
  end
end

RSpec.configure do |config|
  config.color_enabled = true
  config.tty = true
  config.formatter = 'documentation'
  config.include Killbill::Plugin::SpecHelper
  config.before :each do
    reinitialize_active_record
  end
end

begin
  require 'securerandom'
  SecureRandom.uuid
rescue LoadError, NoMethodError
  # See http://jira.codehaus.org/browse/JRUBY-6176
  module SecureRandom
    def self.uuid
      ary = self.random_bytes(16).unpack("NnnnnN")
      ary[2] = (ary[2] & 0x0fff) | 0x4000
      ary[3] = (ary[3] & 0x3fff) | 0x8000
      "%08x-%04x-%04x-%04x-%04x%08x" % ary
    end unless respond_to?(:uuid)
  end
end
