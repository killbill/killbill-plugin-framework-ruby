require 'killbill/plugin'
require 'securerandom'

module Killbill
  module Plugin
    class Invoice < Notification

      def get_additional_invoice_items(invoice, dry_run, properties, context)
        []
      end


      # Helper method to build a new item from an existing one
      def build_item(item_model, amount, description = nil, type = :EXTERNAL_CHARGE)
        item = Model::InvoiceItem.new

        item.created_date    = item_model.created_date
        item.updated_date    = item_model.updated_date
        item.invoice_id      = item_model.invoice_id
        item.account_id      = item_model.account_id
        item.currency        = item_model.currency
        item.bundle_id       = item_model.bundle_id
        item.subscription_id = item_model.subscription_id
        item.start_date      = item_model.start_date
        item.end_date        = item_model.end_date
        item.plan_name       = item_model.plan_name
        item.phase_name      = item_model.phase_name
        item.usage_name      = item_model.usage_name

        item.linked_item_id = item_model.id

        item.id                = SecureRandom.uuid
        item.invoice_item_type = type
        item.amount            = amount
        item.description       = description
        item.rate              = nil

        item
      end
    end
  end
end
