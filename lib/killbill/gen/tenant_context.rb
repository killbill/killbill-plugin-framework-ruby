
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Model

      class TenantContext

        include com.ning.billing.util.callcontext.TenantContext

        attr_reader :tenant_id

        def initialize(tenant_id)
          @tenant_id = tenant_id
        end
      end
    end
  end
end
