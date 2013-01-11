killbill-plugin-framework-ruby
==============================

Framework to write Killbill plugins in Ruby.

There are various types of plugins one can write for Killbill:

1. notifications plugins, which listen to external bus events and can react to it
2. payment plugins, which are used to issue payments against a payment gateway

How to write a Notification plugin
----------------------------------

    require 'killbill'

    class MyNotificationPlugin < Killbill::Plugin::Notification
      # Overriding this method is optional, only if you need to do some initialization work
      def start_plugin
        puts "MyNotificationPlugin plugin starting"
        super
        puts "MyNotificationPlugin plugin started"
      end

      # Invoked each time an event is received
      def on_event(event)
        puts "Received Killbill event #{event}"
      end

      # Overriding this method is optional, only if you need to do some tear down work
      def stop_plugin
        puts "MyNotificationPlugin plugin stopping"
        super
        puts "MyNotificationPlugin plugin stopped"
      end
    end

How to write a Payment plugin
-----------------------------

    require 'killbill'

    class MyPaymentPlugin < Killbill::Plugin::Payment
      def start_plugin
        puts "MyPaymentPlugin plugin starting"
        super
        puts "MyPaymentPlugin plugin started"
      end

      def charge(killbill_account_id, killbill_payment_id, amount_in_cents, options = {})
      end

      def refund(killbill_account_id, killbill_payment_id, amount_in_cents, options = {})
      end

      def get_payment_info(killbill_payment_id, options = {})
      end

      def add_payment_method(payment_method, options = {})
      end

      def delete_payment_method(external_payment_method_id, options = {})
      end

      def update_payment_method(payment_method, options = {})
      end

      def set_default_payment_method(payment_method, options = {})
      end

      def create_account(killbill_account, options = {})
      end

      # Overriding this method is optional, only if you need to do some tear down work
      def stop_plugin
        puts "MyPaymentPlugin plugin stopping"
        super
        puts "MyPaymentPlugin plugin stopped"
      end
    end