
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Model

      class InvoicePayment

        include com.ning.billing.invoice.api.InvoicePayment

        attr_reader :id, :created_date, :updated_date, :payment_id, :type, :invoice_id, :payment_date, :amount, :currency, :linked_invoice_payment_id, :payment_cookie_id

        def initialize(id, created_date, updated_date, payment_id, type, invoice_id, payment_date, amount, currency, linked_invoice_payment_id, payment_cookie_id)
          @id = id
          @created_date = created_date
          @updated_date = updated_date
          @payment_id = payment_id
          @type = type
          @invoice_id = invoice_id
          @payment_date = payment_date
          @amount = amount
          @currency = currency
          @linked_invoice_payment_id = linked_invoice_payment_id
          @payment_cookie_id = payment_cookie_id
        end
      end
    end
  end
end
