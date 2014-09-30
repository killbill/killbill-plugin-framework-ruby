require 'active_record'
require 'active_record/connection_adapters/jdbc_adapter'

module ActiveRecord
  module ConnectionAdapters
    class JdbcConnection

      # Sets the connection factory from the available configuration.
      #
      # This differs from the original implementation in the following ways:
      #   * We attempt to lookup the JNDI data source multiple times, to handle transient lookup issues
      #   * If the data source is unavailable, we don't fallback to straight JDBC (which is often not configured anyways)
      #   * In the failure scenario, inspect the exception instead of displaying e.message, which is often empty in our testing
      def setup_connection_factory
        if self.class.jndi_config?(config)
          setup_done   = false
          jndi_retries = self.class.jndi_retries(config)

          1.upto(jndi_retries) do |i|
            begin
              setup_jndi_factory
              setup_done = true
              break
            rescue => e
              warn "JNDI data source unavailable: #{e.inspect} (attempt ##{i})"
            end
          end

          raise "JNDI data source unavailable (tried #{jndi_retries} times)" unless setup_done
        else
          setup_jdbc_factory
        end
      end

      def self.jndi_retries(config)
        (config[:jndi_retries] || 5).to_i
      end

      protected

      def setup_jndi_factory
        data_source = config[:data_source] || Java::JavaxNaming::InitialContext.new.lookup(config[:jndi].to_s)

        @jndi                   = true
        # Really slow under high load (see https://github.com/jruby/activerecord-jdbc-adapter/pull/588).
        #self.connection_factory = JdbcConnectionFactory.impl { data_source.connection }
        self.connection_factory = RubyJdbcConnectionFactory.new(data_source)
      end

      class RubyJdbcConnectionFactory
        include JdbcConnectionFactory

        def initialize(data_source)
          @data_source = data_source
        end

        def new_connection
          @data_source.connection
        end
      end
    end
  end
end

require 'active_record/persistence'

module ActiveRecord
  module Persistence

    # Creates a record with values matching those of the instance attributes
    # and returns its id.
    def _create_record(attribute_names = @attributes.keys)
      attributes_values = arel_attributes_with_values_for_create(attribute_names)

      new_id = self.class.unscoped.insert attributes_values

      # Under heavy load and concurrency, write_attribute_with_type_cast sometimes fail to set the id.
      # Even though self.class.primary_key returns 'id' and new_id is correctly populated from the database
      # (see last_insert_id in activerecord-jdbc-adapter-1.3.9/lib/arjdbc/jdbc/adapter.rb), both self.id ||= new_id
      # and self.id = new_id sometimes don't set the id. I couldn't quite figure it out.
      # A workaround seems to be to retry the assignment (see also activerecord-4.1.5/lib/active_record/attribute_methods/primary_key.rb).
      if self.class.primary_key
        self.id ||= new_id
        self.id ||= new_id if id.nil?
        raise "Unable to set id (new_id=#{new_id}) for #{self.inspect}" if id.nil?
      end

      @new_record = false
      id
    end
  end
end
