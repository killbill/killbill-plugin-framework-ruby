module Killbill
  module Plugin
    module ActiveMerchant
      module Sinatra
        enable :sessions

        include ::ActionView::Helpers::FormTagHelper
        include ::Killbill::Plugin::ActiveMerchant::ActiveRecordHelper

        helpers do
          def config(kb_tenant_id=nil)
            ::Killbill::Plugin::ActiveMerchant.config(kb_tenant_id)
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
          close_connection(logger)
        end
      end
    end
  end
end
