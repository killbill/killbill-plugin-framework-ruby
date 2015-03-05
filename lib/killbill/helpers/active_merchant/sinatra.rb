module Killbill
  module Plugin
    module ActiveMerchant
      module Sinatra
        enable :sessions

        include ::ActionView::Helpers::FormTagHelper

        helpers do
          def config
            ::Killbill::Plugin::ActiveMerchant.config
          end

          def logger
            ::Killbill::Plugin::ActiveMerchant.logger
          end

          def required_parameter!(parameter_name, parameter_value, message='must be specified!')
            halt 400, "#{parameter_name} #{message}" if parameter_value.blank?
          end
        end

        after do
          # return DB connections to the Pool if required
          pool = ::ActiveRecord::Base.connection_pool
          if pool.active_connection?
            ::ActiveRecord::Base.connection.close # check-in to pool
          end
        end
      end
    end
  end
end
