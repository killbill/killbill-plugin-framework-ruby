
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Model

      class InvoiceItem

        include com.ning.billing.invoice.api.InvoiceItem

        attr_reader :id, :created_date, :updated_date, :invoice_item_type, :invoice_id, :account_id, :start_date, :end_date, :amount, :currency, :description, :bundle_id, :subscription_id, :plan_name, :phase_name, :rate, :linked_item_id

        def initialize(id, created_date, updated_date, invoice_item_type, invoice_id, account_id, start_date, end_date, amount, currency, description, bundle_id, subscription_id, plan_name, phase_name, rate, linked_item_id)
          @id = id
          @created_date = created_date
          @updated_date = updated_date
          @invoice_item_type = invoice_item_type
          @invoice_id = invoice_id
          @account_id = account_id
          @start_date = start_date
          @end_date = end_date
          @amount = amount
          @currency = currency
          @description = description
          @bundle_id = bundle_id
          @subscription_id = subscription_id
          @plan_name = plan_name
          @phase_name = phase_name
          @rate = rate
          @linked_item_id = linked_item_id
        end
      end
    end
  end
end
