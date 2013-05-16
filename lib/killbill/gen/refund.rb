
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Model

      class Refund

        include com.ning.billing.payment.api.Refund

        attr_reader :id, :created_date, :updated_date, :payment_id, :is_adjusted, :refund_amount, :currency, :effective_date, :plugin_detail

        def initialize(id, created_date, updated_date, payment_id, is_adjusted, refund_amount, currency, effective_date, plugin_detail)
          @id = id
          @created_date = created_date
          @updated_date = updated_date
          @payment_id = payment_id
          @is_adjusted = is_adjusted
          @refund_amount = refund_amount
          @currency = currency
          @effective_date = effective_date
          @plugin_detail = plugin_detail
        end
      end
    end
  end
end
