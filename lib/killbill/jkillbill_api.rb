require 'killbill/jconverter'

module Killbill
  module Plugin

    class JKillbillApi

      attr_writer :account_user_api,
                  :analytics_sanity_api,
                  :analytics_user_api,
                  :catalog_user_api,
                  :entitlement_migration_api,
                  :entitlement_timeline_api,
                  :entitlement_transfer_api,
                  :entitlement_user_api,
                  :invoice_migration_api,
                  :invoice_payment_api,
                  :invoice_user_api,
                  :meter_user_api,
                  :overdue_user_api,
                  :payment_api,
                  :tenant_user_api,
                  :usage_user_api,
                  :audit_user_api,
                  :custom_field_user_api,
                  :export_user_api,
                  :tag_user_api


      def initialize(plugin_name, services)
        @plugin_name = plugin_name
        @plugged_services = []
        services.each do |service_name, service_instance|
          begin
            self.send("#{service_name}=", service_instance)
            @plugged_services << service_instance
          rescue NoMethodError
            # Expected for non APIs (e.g. logger)
            #warn "Ignoring unsupported service: #{service_name}"
          end
        end
      end

      def proxy_api(method_name, *args)
        @plugged_services.each do |s|
          puts "#{s.inspect}"
          if s.class.method_defined?(method_name)
            puts "Found service #{s.to_s} : #{method_name}"
            return do_call_handle_exception(s, method_name, *args)
          end
        end
        raise APINotAvailableError.new("API #{method_name} is not available")
      end

      private

      def do_call_handle_exception(delegate_service, method_name, *args)
        begin
          # STEPH TODO hack tenant_id
          call_context = create_call_context(nil, nil, nil, nil)
          jargs = convert_args(method_name, args)
          #puts "JARGS = #{jargs}"
          res = delegate_service.send(method_name, *jargs, call_context)
          if res.java_kind_of? Java::com.ning.billing.account.api.Account
            return JConverter.from_account(res)
          end
        rescue Exception => e
          wrap_and_throw_exception(method_name, e)
        end
      end

      def wrap_and_throw_exception(api, e)

        raise e

        message = "#{api} failure: #{e}"
        unless e.backtrace.nil?
          message = "#{message}\n#{e.backtrace.join("\n")}"
        end
        raise ApiErrorException.new("#{api} failure : #{e.message}")
      end

      def convert_args(api, args)
        args.collect! do |a|
          if a.is_a? Killbill::Plugin::Gen::AccountData
            return JConverter.to_account_data(a)
          elsif a.is_a? Killbill::Plugin::Gen::UUID
            return JConverter.to_uuid(a)
          else
            a
          end
        end
      end


      def create_tenant_context(tenant_id)
        Killbill::Plugin::Gen::TenantContext.new(0)
      end

      def create_call_context(tenant_id, user_token, reason_code, comments)
        user_token = user_token.nil? ? java.util.UUID.randomUUID() : to_uuid(user_token)
        created_date = org.joda.time.DateTime.new(org.joda.time.DateTimeZone::UTC)
        updated_date = created_date

        Killbill::Plugin::Gen::CallContext.new(tenant_id,
                                               user_token,
                                               @plugin_name,
                                               Java::com.ning.billing.util.callcontext.CallOrigin::EXTERNAL,
                                               Java::com.ning.billing.util.callcontext.UserType::SYSTEM,
                                               reason_code,
                                               comments,
                                               created_date,
                                               updated_date)
      end

      class ApiErrorException < Exception
      end

      class APINotAvailableError < NotImplementedError
      end

    end
  end
end
