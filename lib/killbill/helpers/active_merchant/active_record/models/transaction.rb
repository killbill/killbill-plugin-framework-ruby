module Killbill
  module Plugin
    module ActiveMerchant
      module ActiveRecord
        require 'active_record'

        class Transaction < ::ActiveRecord::Base

          belongs_to :response

          attr_accessible :amount_in_cents,
                          :currency,
                          :api_call,
                          :kb_payment_id

          def self.from_kb_payment_id(kb_payment_id)
            transaction_from_kb_payment_id :charge, kb_payment_id, :single
          end

          def self.refunds_from_kb_payment_id(kb_payment_id)
            transaction_from_kb_payment_id :refund, kb_payment_id, :multiple
          end

          def self.find_candidate_transaction_for_refund(kb_payment_id, amount_in_cents)
            # Find one successful charge which amount is at least the amount we are trying to refund
            transactions = Transaction.where("#{Transaction.table_name}.amount_in_cents >= ?", amount_in_cents)
                                      .find_all_by_api_call_and_kb_payment_id(:charge, kb_payment_id)
            raise "Unable to find transaction id for payment #{kb_payment_id}" if transactions.size == 0

            # We have candidates, but we now need to make sure we didn't refund more than for the specified amount
            amount_refunded_in_cents = Transaction.where("api_call = ? and kb_payment_id = ?", :refund, kb_payment_id)
                                                  .sum("amount_in_cents")

            amount_left_to_refund_in_cents = -amount_refunded_in_cents
            transactions.map { |transaction| amount_left_to_refund_in_cents += transaction.amount_in_cents }
            raise "Amount #{amount_in_cents} too large to refund for payment #{kb_payment_id}" if amount_left_to_refund_in_cents < amount_in_cents

            transactions.first
          end

          private

          def self.transaction_from_kb_payment_id(api_call, kb_payment_id, how_many)
            transactions = find_all_by_api_call_and_kb_payment_id(api_call, kb_payment_id)
            raise "Unable to find transaction id for payment #{kb_payment_id}" if transactions.empty?
            if how_many == :single
              raise "Kill Bill payment #{kb_payment_id} mapping to multiple plugin transactions" if transactions.size > 1
              transactions[0]
            else
              transactions
            end
          end
        end
      end
    end
  end
end