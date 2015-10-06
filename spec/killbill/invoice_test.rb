require 'killbill/invoice'

# See invoice_plugin_api_spec.rb
module Killbill
  module Plugin
    class InvoiceTest < Invoice

      def get_additional_invoice_items(invoice, dry_run, properties, context)
        additional_items = []
        invoice.invoice_items.each do |original_item|
          additional_items << build_item(original_item, original_item.amount * 7 / 100, 'Tax item', :TAX)
          additional_items << build_item(original_item, original_item.amount * 2, 'Charge item', :EXTERNAL_CHARGE)
        end

        additional_items
      end

    end
  end
end
