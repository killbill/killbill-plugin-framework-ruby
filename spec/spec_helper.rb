

require 'java'

require 'bundler'
require 'logger'

require 'killbill'
require 'killbill/killbill_logger'
# JRuby specific, not required by default
require 'killbill/http_servlet'

require 'killbill/payment_test'
require 'killbill/notification_test'


%w(
  MockAccountUserApi
  MockEntitlementUserApi
).each do |api|
  begin
    java_import "com.ning.billing.mock.api.#{api}"
  rescue LoadError
  end
end

require 'rspec'

RSpec.configure do |config|
  config.color_enabled = true
  config.tty = true
  config.formatter = 'documentation'
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
