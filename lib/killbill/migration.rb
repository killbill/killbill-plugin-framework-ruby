require 'logger'

require 'active_record'
require 'arjdbc'

begin
  require 'jdbc/mariadb'
  Jdbc::MariaDB.load_driver
rescue LoadError
# ignored
end

begin
  require 'jdbc/postgres'
  Jdbc::Postgres.load_driver
rescue LoadError
# ignored
end

module Killbill
  class Migration

    class << self
      attr_accessor :ar_patched
    end

    def initialize(plugin_name, config = nil, logger = Logger.new(STDOUT))
      configure_logging(logger)
      configure_migration(plugin_name)
      configure_connection(config)

      monkey_patch_ar
    end

    def sql_for_migration(migrations_paths = ActiveRecord::Migrator.migrations_paths)
      ActiveRecord::Base.connection.readonly = true

      ActiveRecord::Migrator.migrate(migrations_paths)

      ActiveRecord::Base.connection.migration_statements
    end

    def migrate(migrations_paths = ActiveRecord::Migrator.migrations_paths)
      ActiveRecord::Base.connection.readonly = false

      ActiveRecord::Migrator.migrate(migrations_paths)
    end

    def current_version
      ActiveRecord::Migrator.current_version
    end

    def sql_dump(stream = StringIO.new)
      Dir.mktmpdir do |dir|
        filename = File.join(dir, 'structure.sql')
        ActiveRecord::Tasks::DatabaseTasks.structure_dump(@config, filename)
        stream.write(File.read(filename))
      end
      stream
    end

    def ruby_dump(stream = StringIO.new)
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
    end

    private

    def configure_logging(logger)
      verbose = ENV['VERBOSE'] ? ENV['VERBOSE'] == 'true' : false

      ActiveRecord::Base.logger = logger
      ActiveRecord::Base.logger.level = verbose ? Logger::DEBUG : Logger::INFO

      ActiveRecord::Migration.verbose = verbose
    end

    def configure_migration(plugin_name)
      ActiveRecord::SchemaMigration.table_name_prefix = "#{plugin_name}_"
    end

    def configure_connection(config)
      config ||= {}
      db_config = {
          :adapter => ENV['ADAPTER'] || :mysql,
          :driver => ENV['DRIVER'] || 'org.mariadb.jdbc.Driver',
          :username => ENV['USERNAME'] || 'killbill',
          :password => ENV['PASSWORD'] || 'killbill',
          :database => ENV['DB'] || 'killbill',
          :host => ENV['HOST'] || '127.0.0.1'
      }
      config_with_defaults = db_config.merge(config)
      ActiveRecord::Base.establish_connection(config_with_defaults)

      @config = config_with_defaults.stringify_keys
    end

    def monkey_patch_ar
      return if self.class.ar_patched

      ActiveRecord::Base.connection.class.class_eval do
        attr_accessor :migration_statements
        attr_accessor :readonly

        [:exec_query, :exec_insert, :exec_delete, :exec_update, :exec_query_raw, :execute].each do |method|
          send(:alias_method, "old_#{method}".to_sym, method)

          define_method(method) do |sql, *args|
            migration_sql = /^(create|alter|drop|insert|delete|update)/i.match(sql)

            @migration_statements ||= []
            @migration_statements << "#{sql};" if migration_sql

            send("old_#{method}", sql, *args) if !migration_sql || (migration_sql && !@readonly)
          end
        end
      end
      self.class.ar_patched = true
    end
  end
end
