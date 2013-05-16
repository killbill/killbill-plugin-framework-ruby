require 'killbill/payment'

module Killbill
  module Plugin
    class PaymentTest < Payment

      def initialize(*args)
        @raise_exception = false
      end

      def process_payment(kb_account_id, kb_payment_id, kb_payment_method_id, amount_in_cents, currency, options = {})
        if @raise_exception
          raise StandardError.new("Test exception")
        else
          Killbill::Plugin::Gen::PaymentInfoPlugin.new(amount_in_cents, DateTime.now, DateTime.now, Killbill::Plugin::Gen::PaymentPluginStatus::PROCESSED, "gateway_error", "gateway_error_code", nil, nil)
        end
      end

      def get_payment_info(kb_account_id, kb_payment_id, options = {})
        if @raise_exception
          raise StandardError.new("Test exception")
        else
          Killbill::Plugin::Gen::PaymentInfoPlugin.new(0, DateTime.now, DateTime.now, Killbill::Plugin::Gen::PaymentPluginStatus::PROCESSED, "gateway_error", "gateway_error_code", nil, nil)
        end
      end

      def process_refund(kb_account_id, kb_payment_id, amount_in_cents, currency, options = {})
        if @raise_exception
          raise StandardError.new("Test exception")
        else
          Killbill::Plugin::Gen::RefundInfoPlugin.new(5000, DateTime.now, DateTime.now, Killbill::Plugin::Gen::RefundPluginStatus::PROCESSED, "gateway_error", "gateway_error_code", nil)
        end
      end

      def add_payment_method(kb_account_id, kb_payment_method_id, payment_method_props, set_default, options = {})
        if @raise_exception
          raise StandardError.new("Test exception")
        end
      end

      def delete_payment_method(kb_account_id, kb_payment_method_id, options = {})
        if @raise_exception
          raise StandardError.new("Test exception")
        end
      end

      def get_payment_method_detail(kb_account_id, kb_payment_method_id, options = {})
        if @raise_exception
          raise StandardError.new("Test exception")
        else
          Killbill::Plugin::Gen::PaymentMethodPlugin.new("foo", true, [], nil, "type", "cc_name", "cc_type", "cc_expiration_month", "cc_expiration_year", "cc_last4", "address1", "address2", "city", "state", "zip", "country")
        end
      end

      def set_default_payment_method(kb_account_id, kb_payment_method_id, options = {})
        if @raise_exception
          raise StandardError.new("Test exception")
        end
      end

      def get_payment_methods(kb_account_id, options = {})
        if @raise_exception
          raise StandardError.new("Test exception")
        else
          [Killbill::Plugin::Gen::PaymentMethodInfoPlugin.new(kb_account_id, kb_account_id, true, "external_payment_method_id")]
        end
      end

      def reset_payment_methods(kb_account_id, payment_methods)
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
