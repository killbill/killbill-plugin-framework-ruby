
#
# Ruby classes automatically generated from java classes-- don't edit
#
module Killbill
  module Plugin
    module Gen

      class Payment

        attr_reader :id, :created_date, :updated_date, :account_id, :invoice_id, :payment_method_id, :payment_number, :amount, :paid_amount, :effective_date, :currency, :payment_status, :ext_first_payment_id_ref, :ext_second_payment_id_ref, :payment_info_plugin

        def initialize(id, created_date, updated_date, account_id, invoice_id, payment_method_id, payment_number, amount, paid_amount, effective_date, currency, payment_status, ext_first_payment_id_ref, ext_second_payment_id_ref, payment_info_plugin)
          @id = id
          @created_date = created_date
          @updated_date = updated_date
          @account_id = account_id
          @invoice_id = invoice_id
          @payment_method_id = payment_method_id
          @payment_number = payment_number
          @amount = amount
          @paid_amount = paid_amount
          @effective_date = effective_date
          @currency = currency
          @payment_status = payment_status
          @ext_first_payment_id_ref = ext_first_payment_id_ref
          @ext_second_payment_id_ref = ext_second_payment_id_ref
          @payment_info_plugin = payment_info_plugin
        end
      end
    end
  end
end
