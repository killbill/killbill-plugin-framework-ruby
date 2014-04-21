module Killbill
  module Plugin
    module ActiveMerchant
      module Helpers

        # Useful helper to extract params from AM response objects, e.g. extract(response, 'card', 'address_country')
        def extract(response, key1, key2=nil, key3=nil)
          return nil if response.nil? || response.params.nil?
          level1 = response.params[key1]

          if level1.nil? or (key2.nil? and key3.nil?)
            return level1
          end
          level2 = level1[key2]

          if level2.nil? or key3.nil?
            return level2
          else
            return level2[key3]
          end
        end
      end
    end
  end
end
