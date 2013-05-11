require 'killbill/jconverter'

module Killbill
  module Plugin

    java_package 'com.ning.billing.beatrix.bus.api'
    class JEvent

      include Java::com.ning.billing.beatrix.bus.api.ExtBusEvent

      attr_reader :event_type, :object_type, :object_id, :account_id, :tenant_id

      def initialize(event_type, object_type, object_id, account_id, tenant_id)
        @event_type = event_type
        @object_type = object_type
        @object_id = object_id
        @account_id = account_id
        @tenant_id = tenant_id
      end

      java_signature 'Java::com.ning.billing.beatrix.bus.api.ExtBusEventType getEventType()'
      def get_event_type
        @event_type
      end

      java_signature 'Java::com.ning.billing.ObjectType getObjectType()'
      def get_object_type
        @object_type
      end

      java_signature 'java.lang.UUID getObjectId()'
      def get_object_id
        @object_id
      end

      java_signature 'java.lang.UUID getAccountId()'
      def get_account_id
        @account_id
      end

      java_signature 'java.lang.UUID getTenantId()'
      def get_tenant_id
        @tenant_id
      end

      class << self
        def to_event(jevent)
          event_type = jevent.get_event_type.to_s
          object_type = jevent.get_object_type.to_s
          object_id = JConverter.from_uuid(jevent.get_object_id)
          account_id = JConverter.from_uuid(jevent.get_account_id)
          tenant_id = JConverter.from_uuid(jevent.get_tenant_id)
          Event.new(event_type, object_type, object_id, account_id, tenant_id)
        end
      end
    end
  end
end
