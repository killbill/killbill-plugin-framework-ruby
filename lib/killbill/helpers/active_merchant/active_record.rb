module Killbill
  module Plugin
    module ActiveMerchant
      module ActiveRecord
        Dir[File.dirname(__FILE__) + '/active_record/models/*.rb'].each do |f|
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
end
