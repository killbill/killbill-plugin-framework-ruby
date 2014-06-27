module Killbill
  module Plugin
    module ActiveMerchant
      module ActiveRecord
        require 'active_record'

        class Transaction < ::ActiveRecord::Base

          self.abstract_class = true

          def transactions_from_kb_payment_id(kb_payment_id, kb_tenant_id)
            if kb_tenant_id.nil?
              where(:kb_payment_id => kb_payment_id)
            else
              where(:kb_payment_id => kb_payment_id, :kb_tenant_id => kb_tenant_id)
            end
          end

          [:authorize, :capture, :purchase, :credit, :refund].each do |transaction_type|
            define_method("#{transaction_type.to_s}s_from_kb_payment_id") do |kb_payment_id, kb_tenant_id|
              transaction_from_kb_payment_id transaction_type, kb_payment_id, kb_tenant_id, :multiple
            end

            define_method("#{transaction_type.to_s}_from_kb_payment_transaction_id") do |kb_payment_transaction_id, kb_tenant_id|
              transaction_from_kb_payment_transaction_id transaction_type, kb_payment_transaction_id, kb_tenant_id, :single
            end
          end

          # For convenience
          alias_method :authorizations_from_kb_payment_id, :authorizes_from_kb_payment_id
          alias_method :authorization_from_kb_payment_transaction_id, :authorize_from_kb_payment_transaction_id

          # void is special: unique void per payment_id
          def self.void_from_kb_payment_id(kb_payment_id, kb_tenant_id)
            transaction_from_kb_payment_id :void, kb_payment_id, kb_tenant_id, :single
          end

          def self.void_from_kb_payment_transaction_id(kb_payment_transaction_id, kb_tenant_id)
            transaction_from_kb_payment_transaction_id :void, kb_payment_transaction_id, kb_tenant_id, :single
          end

          def self.find_candidate_transaction_for_refund(kb_payment_id, kb_tenant_id, amount_in_cents)
            begin
              do_find_candidate_transaction_for_refund :authorize, kb_payment_id, kb_tenant_id, amount_in_cents
            rescue
              do_find_candidate_transaction_for_refund :purchase, kb_payment_id, kb_tenant_id, amount_in_cents
            end
          end

          private

          def self.do_find_candidate_transaction_for_refund(api_call, kb_payment_id, kb_tenant_id, amount_in_cents)
            if kb_tenant_id.nil?
              transactions = where('amount_in_cents >= ? AND api_call = ? AND kb_payment_id = ?', amount_in_cents, api_call, kb_payment_id)
            else
              transactions = where('amount_in_cents >= ? AND api_call = ? AND kb_tenant_id = ? AND kb_payment_id = ?', amount_in_cents, api_call, kb_tenant_id, kb_payment_id)
            end
            # Find one successful charge which amount is at least the amount we are trying to refund
            transactions = where('amount_in_cents >= ? AND api_call = ? AND kb_tenant_id = ? AND kb_payment_id = ?', amount_in_cents, api_call, kb_tenant_id, kb_payment_id)
            raise "Unable to find transaction for payment #{kb_payment_id} and api_call #{api_call}" if transactions.size == 0

            # We have candidates, but we now need to make sure we didn't refund more than for the specified amount
            amount_refunded_in_cents = where('api_call = ? and kb_payment_id = ?', :refund, kb_payment_id)
                                       .sum('amount_in_cents')

            amount_left_to_refund_in_cents = -amount_refunded_in_cents
            transactions.map { |transaction| amount_left_to_refund_in_cents += transaction.amount_in_cents }
            raise "Amount #{amount_in_cents} too large to refund for payment #{kb_payment_id}" if amount_left_to_refund_in_cents < amount_in_cents

            transactions.first
          end

          [:kb_payment_id, :kb_payment_transaction_id].each do |attribute|
            define_method("transaction_from_#{attribute.to_s}") do |api_call, attribute_value, kb_tenant_id, how_many|
              if kb_tenant_id.nil?
                transactions = where("api_call = ? AND #{attribute.to_s} = ?", api_call, attribute_value)
              else
                transactions = where("api_call = ? AND kb_tenant_id = ? AND #{attribute.to_s} = ?", api_call, kb_tenant_id, attribute_value)
              end
              raise "Unable to find transaction id for #{attribute} = #{attribute_value}" if transactions.empty?
              if how_many == :single
                raise "Kill Bill #{attribute} = #{attribute_value} mapping to multiple plugin transactions" if transactions.size > 1
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
end
