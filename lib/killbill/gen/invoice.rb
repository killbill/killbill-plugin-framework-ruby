
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Gen

      class Invoice

        attr_reader :id, :created_date, :updated_date, :invoice_items, :number_of_items, :payments, :number_of_payments, :account_id, :invoice_number, :invoice_date, :target_date, :currency, :paid_amount, :original_charged_amount, :charged_amount, :credited_amount, :refunded_amount, :balance, :is_migration_invoice

        def initialize(id, created_date, updated_date, invoice_items, number_of_items, payments, number_of_payments, account_id, invoice_number, invoice_date, target_date, currency, paid_amount, original_charged_amount, charged_amount, credited_amount, refunded_amount, balance, is_migration_invoice)
          @id = id
          @created_date = created_date
          @updated_date = updated_date
          @invoice_items = invoice_items
          @number_of_items = number_of_items
          @payments = payments
          @number_of_payments = number_of_payments
          @account_id = account_id
          @invoice_number = invoice_number
          @invoice_date = invoice_date
          @target_date = target_date
          @currency = currency
          @paid_amount = paid_amount
          @original_charged_amount = original_charged_amount
          @charged_amount = charged_amount
          @credited_amount = credited_amount
          @refunded_amount = refunded_amount
          @balance = balance
          @is_migration_invoice = is_migration_invoice
        end
      end
    end
  end
end
