
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Gen

      class InvoicePayment

        attr_reader :payment_id, :type, :invoice_id, :payment_date, :amount, :currency, :linked_invoice_payment_id, :payment_cookie_id

        def initialize(payment_id, type, invoice_id, payment_date, amount, currency, linked_invoice_payment_id, payment_cookie_id)
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
