module Killbill
  module Plugin
    module ActiveMerchant
      require 'killbill'

      require 'killbill/ext/active_merchant/jdbc_connection'
      require 'killbill/ext/active_merchant/proxy_support'

      require 'active_support/core_ext'
      require File.dirname(__FILE__) + '/active_merchant/core_ext.rb'
      require File.dirname(__FILE__) + '/active_merchant/configuration.rb'

      Dir[File.dirname(__FILE__) + '/active_merchant/*.rb'].each do |f|
        # Get camelized class name
        filename = File.basename(f, '.rb')
        # Camelize the string to get the class name
        class_name = filename.camelize.to_sym

        # Register for autoloading
        autoload class_name, f
      end
    end
  end
end
