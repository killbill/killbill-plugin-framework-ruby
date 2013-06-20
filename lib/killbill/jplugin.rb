require 'java'

require 'pathname'

require 'killbill/http_servlet'
require 'killbill/creator'

include Java

module Killbill
  # There are various types of plugins one can write for Killbill:
  #
  #   1)  notifications plugins, which listen to external bus events and can react to it
  #   2)  payment plugins, which are used to issue payments against a payment gateway
  module Plugin
    class JPlugin


      attr_reader :delegate_plugin,
                  # Called by the Killbill lifecycle to register the servlet
                  :rack_handler

      # Called by the Killbill lifecycle when initializing the plugin
      def start_plugin
        @delegate_plugin.start_plugin
        configure_rack_handler
      end

      # Called by the Killbill lifecycle when stopping the plugin
      def stop_plugin
        unconfigure_rack_handler
        @delegate_plugin.stop_plugin
      end

      def is_active
        @delegate_plugin.active
      end

      # Called by the Killbill lifecycle when instantiating the plugin
      def initialize(plugin_class_name, services = {})
        @delegate_plugin = Creator.new(plugin_class_name).create(services)
      end

      def logger
        require 'logger'
        @delegate_plugin.nil? ? ::Logger.new(STDOUT) : @delegate_plugin.logger
      end

      protected

      def configure_rack_handler
        config_ru = Pathname.new("#{@delegate_plugin.root}/config.ru").expand_path
        if config_ru.file?
          logger.info "Found Rack configuration file at #{config_ru.to_s}"
          @rack_handler = Killbill::Plugin::RackHandler.instance
          @rack_handler.configure(logger, config_ru.to_s) unless @rack_handler.configured?
        else
          logger.info "No Rack configuration file found at #{config_ru.to_s}"
          nil
        end
      end

      def unconfigure_rack_handler
        @rack_handler.unconfigure unless @rack_handler.nil?
      end

      def do_call_handle_exception(method_name, *args)
        begin
          rargs = convert_args(method_name, args)
          res = @delegate_plugin.send(method_name.to_s.snake_case.to_sym, *rargs)
          yield(res)
        rescue Exception => e
          wrap_and_throw_exception(method_name, e)
        ensure
          @delegate_plugin.after_request
        end
      end

      def wrap_and_throw_exception(api, e)
        message = "#{api} failure: #{e}"
        unless e.backtrace.nil?
          message = "#{message}\n#{e.backtrace.join("\n")}"
        end
        logger.warn message
        raise Java::com.ning.billing.payment.plugin.api.PaymentPluginApiException.new("#{api} failure", e.message)
      end

      def convert_args(api, args)
        args.collect! do |a|
          if a.nil?
            nil
          elsif a.java_kind_of? java.util.UUID
            a.nil? ? nil : a.to_s
          elsif a.java_kind_of? java.math.BigDecimal
            a.nil? ? 0 : a.to_s.to_i
          elsif a.java_kind_of? Java::com.ning.billing.catalog.api.Currency
            a.to_string
          elsif a.java_kind_of? Java::com.ning.billing.payment.api.PaymentMethodPlugin
            Killbill::Plugin::Model::PaymentMethodPlugin.new.to_ruby(a)
          elsif a.java_kind_of? Java::com.ning.billing.notification.plugin.api.ExtBusEvent
            Killbill::Plugin::Model::ExtBusEvent.new.to_ruby(a)
          elsif ((a.java_kind_of? Java::boolean) || (a.java_kind_of? java.lang.Boolean))
          elsif ((a.java_kind_of? TrueClass) || (a.java_kind_of? FalseClass))
            if a.nil?
              false
            else
              b_value = (a.java_kind_of? java.lang.Boolean) ? a.boolean_value : a
              b_value ? true : false
            end
          elsif a.java_kind_of? java.util.List
            result = Array.new
            if a.size > 0
              first_element = a.get(0)
              if first_element.java_kind_of? Java::com.ning.billing.payment.plugin.api.PaymentMethodInfoPlugin
                a.each do |el|
                  result << Killbill::Plugin::Model::PaymentMethodInfoPlugin.new.to_ruby(el)
                end
              else
                raise Java::com.ning.billing.payment.plugin.api.PaymentPluginApiException.new("#{api} failure", "Unexpected parameter type #{first_element.class} for list")
              end
            end
            result
          elsif a.java_kind_of? Java::com.ning.billing.util.callcontext.CallContext
            Killbill::Plugin::Model::CallContext.new.to_ruby(a)
          elsif a.java_kind_of? Java::com.ning.billing.util.callcontext.TenantContext
            Killbill::Plugin::Model::TenantContext.new.to_ruby(a)
          else
            # Since we don't pass the Context at this point, we can't raise any exceptions for unexpected types.
            raise Java::com.ning.billing.payment.plugin.api.PaymentPluginApiException.new("#{api} failure", "Unexpected parameter type #{a.class}")
          end
        end
        # Remove last argument if this is null (it means we passed a context)
        #args.delete_at(-1) if args[-1].nil?
        #args
      end

    end
  end
end
