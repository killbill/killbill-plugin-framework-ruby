require 'killbill/payment'

module Killbill
  module Plugin
    class PaymentTest < Payment

      def initialize(*args)
        @raise_exception = false
      end

      def purchase_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount_in_cents, currency, properties, context)
        if @raise_exception
          raise StandardError.new("Test exception")
        else
          res = Killbill::Plugin::Model::PaymentTransactionInfoPlugin.new
          res.amount=amount_in_cents
          res.status=:PROCESSED
          res
        end
      end

      def get_payment_info(kb_account_id, kb_payment_id, properties, context)
        if @raise_exception
          raise StandardError.new("Test exception")
        else
          res = Killbill::Plugin::Model::PaymentTransactionInfoPlugin.new
          res.amount=0
          res.status=:PROCESSED
          [res]
        end
      end

      def refund_payment(kb_account_id, kb_payment_id, kb_payment_transaction_id, kb_payment_method_id, amount_in_cents, currency, properties, context)
        if @raise_exception
          raise StandardError.new("Test exception")
        else
          res = Killbill::Plugin::Model::PaymentTransactionInfoPlugin.new
          res.amount=50
          res.status=:PROCESSED
          res
        end
      end

      def add_payment_method(kb_account_id, kb_payment_method_id, payment_method_props, set_default, properties, context)
        if @raise_exception
          raise StandardError.new("Test exception")
        end
      end

      def delete_payment_method(kb_account_id, kb_payment_method_id, properties, context)
        if @raise_exception
          raise StandardError.new("Test exception")
        end
      end

      def get_payment_method_detail(kb_account_id, kb_payment_method_id, properties, context)
        if @raise_exception
          raise StandardError.new("Test exception")
        else
          res = Killbill::Plugin::Model::PaymentMethodPlugin.new
          res.external_payment_method_id="external_payment_method_id"
          res
        end
      end

      def set_default_payment_method(kb_account_id, kb_payment_method_id, properties, context)
        if @raise_exception
          raise StandardError.new("Test exception")
        end
      end

      def get_payment_methods(kb_account_id, refresh_from_gateway, properties, context)
        if @raise_exception
          raise StandardError.new("Test exception")
        else
          res = Killbill::Plugin::Model::PaymentMethodInfoPlugin.new
          res.account_id=kb_account_id
          res.payment_method_id=kb_account_id
          res.is_default=true
          res.external_payment_method_id="dfdf"
          [res]
        end
      end

      def reset_payment_methods(kb_account_id, payment_methods, properties, context)
        if @raise_exception
          raise StandardError.new("Test exception")
        end
      end

      def after_request
      end

      def raise_exception_on_next_calls
        @raise_exception = true
      end

      def clear_exception_on_next_calls
        @raise_exception = false
      end
    end
  end
end
