module Killbill
  module Plugin
    module ActiveMerchant
      require 'killbill'

      require 'killbill/helpers/properties_helper'
      require 'killbill/helpers/active_merchant/active_record/active_record_helper.rb'

      require 'active_support'

      require 'active_support/core_ext'
      require 'killbill/helpers/active_merchant/core_ext'
      require 'killbill/helpers/active_merchant/configuration'

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
