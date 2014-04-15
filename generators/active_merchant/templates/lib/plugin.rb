require 'active_record'
require 'active_merchant'
require 'bigdecimal'
require 'money'
require 'pathname'
require 'sinatra'
require 'singleton'
require 'yaml'

require 'killbill'
require 'killbill/helpers/active_merchant'

require '<%= identifier %>/api'
require '<%= identifier %>/gateway'
require '<%= identifier %>/private_api'

require '<%= identifier %>/models/payment_method'
require '<%= identifier %>/models/response'
require '<%= identifier %>/models/transaction'

class Object
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end
end
