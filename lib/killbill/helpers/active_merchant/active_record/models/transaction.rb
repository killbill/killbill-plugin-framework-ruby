module Killbill
  module Plugin
    module ActiveMerchant
      module ActiveRecord
        require 'active_record'

        class Transaction < ::ActiveRecord::Base

          extend ::Killbill::Plugin::ActiveMerchant::Helpers

          self.abstract_class = true
          # See Response#from_response
          self.record_timestamps = false

          @@quotes_cache = build_quotes_cache

          class << self

            def transactions_from_kb_payment_id(kb_payment_id, kb_tenant_id)
              where(:kb_payment_id => kb_payment_id, :kb_tenant_id => kb_tenant_id).order(:created_at)
            end

            [:authorize, :capture, :purchase, :credit, :refund].each do |transaction_type|
              define_method("#{transaction_type.to_s}s_from_kb_payment_id") do |kb_payment_id, kb_tenant_id|
                transaction_from_kb_payment_id(transaction_type.to_s.upcase, kb_payment_id, kb_tenant_id, :multiple)
              end
            end

            # For convenience
            alias_method :authorizations_from_kb_payment_id, :authorizes_from_kb_payment_id

            # For convenience
            def voids_from_kb_payment_id(kb_payment_id, kb_tenant_id)
              [void_from_kb_payment_id(kb_payment_id, kb_tenant_id)]
            end

            # void is special: unique void per payment_id
            def void_from_kb_payment_id(kb_payment_id, kb_tenant_id)
              transaction_from_kb_payment_id(:VOID, kb_payment_id, kb_tenant_id, :single)
            end

            def from_kb_payment_transaction_id(kb_payment_transaction_id, kb_tenant_id)
              transaction_from_kb_payment_transaction_id(nil, kb_payment_transaction_id, kb_tenant_id, :single)
            end

            def find_candidate_transaction_for_refund(kb_payment_id, kb_tenant_id, transaction_type = nil)
              if transaction_type.nil?
                find_candidate_transaction_for_refund(kb_payment_id, kb_tenant_id, :AUTHORIZE) || find_candidate_transaction_for_refund(kb_payment_id, kb_tenant_id, :PURCHASE)
              else
                do_find_candidate_transaction_for_refund(transaction_type, kb_payment_id, kb_tenant_id)
              end
            end

            private

            # Note: this does not check any amount, as the behavior is gateway specific (some allow to refund more than what was captured):
            # we just want to find the reference transaction to pass the id to the gateway
            def do_find_candidate_transaction_for_refund(transaction_type, kb_payment_id, kb_tenant_id)
              # Assume the last one was successful
              if kb_tenant_id.nil?
                transactions = where("transaction_type = #{@@quotes_cache[transaction_type]} AND kb_tenant_id is NULL AND kb_payment_id = #{@@quotes_cache[kb_payment_id]}").order(:created_at => :desc)
              else
                transactions = where("transaction_type = #{@@quotes_cache[transaction_type]} AND kb_tenant_id = #{@@quotes_cache[kb_tenant_id]} AND kb_payment_id = #{@@quotes_cache[kb_payment_id]}").order(:created_at => :desc)
              end
              transactions.first
            end

            [:kb_payment_id, :kb_payment_transaction_id].each do |attribute|
              define_method("transaction_from_#{attribute.to_s}") do |transaction_type, attribute_value, kb_tenant_id, how_many|
                if kb_tenant_id.nil?
                  if transaction_type.nil?
                    transactions = where("kb_tenant_id is NULL AND #{attribute.to_s} = ?", attribute_value).order(:created_at)
                  else
                    transactions = where("transaction_type = #{@@quotes_cache[transaction_type]} AND kb_tenant_id is NULL AND #{attribute.to_s} = #{@@quotes_cache[attribute_value]}").order(:created_at)
                  end
                else
                  if transaction_type.nil?
                    transactions = where("kb_tenant_id = #{@@quotes_cache[kb_tenant_id]} AND #{attribute.to_s} = #{@@quotes_cache[attribute_value]}").order(:created_at)
                  else
                    transactions = where("transaction_type = #{@@quotes_cache[transaction_type]} AND kb_tenant_id = #{@@quotes_cache[kb_tenant_id]} AND #{attribute.to_s} = #{@@quotes_cache[attribute_value]}").order(:created_at)
                  end
                end
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
end
