require 'highline'
require 'thor'

require 'killbill/migration'

module Killbill
  class Cli < Thor

    include ::Thor::Actions

    class_option :adapter,
                 :type => :string,
                 :default => 'mysql',
                 :desc => 'Database adapter'

    class_option :driver,
                 :type => :string,
                 :default => 'org.mariadb.jdbc.Driver',
                 :desc => 'Database driver'

    class_option :username,
                 :type => :string,
                 :default => 'killbill',
                 :desc => 'Database username'

    class_option :password,
                 :type => :string,
                 :default => 'killbill',
                 :desc => 'Database password'

    class_option :database,
                 :type => :string,
                 :default => 'killbill',
                 :desc => 'Database name'

    class_option :host,
                 :type => :string,
                 :default => '127.0.0.1',
                 :desc => 'Database hostname'

    desc 'current_version plugin_name', 'Display the current migration version'
    def current_version(plugin_name)
      say migration(plugin_name, options).current_version, :green
    end

    method_option :path,
                  :type => :string,
                  :default => ActiveRecord::Migrator.migrations_paths,
                  :desc => 'Folder where to find migration files.'
    desc 'sql_for_migration plugin_name', 'Display the migration SQL'
    def sql_for_migration(plugin_name)
      say migration(plugin_name, options).sql_for_migration(options[:path]).join("\n"), :green
    end

    method_option :path,
                  :type => :string,
                  :default => ActiveRecord::Migrator.migrations_paths,
                  :desc => 'Folder where to find migration files.'
    desc 'migrate plugin_name', 'Run all migrations'
    def migrate(plugin_name)
      migration(plugin_name, options).migrate(options[:path])
    end

    desc 'ruby_dump plugin_name', 'Dump the current schema structure (Ruby)'
    def ruby_dump(plugin_name)
      say migration(plugin_name, options).ruby_dump.string, :green
    end

    desc 'sql_dump plugin_name', 'Dump the current schema structure (SQL)'
    def sql_dump(plugin_name)
      say migration(plugin_name, options).sql_dump.string, :green
    end

    private

    def migration(plugin_name, options)
      Killbill::Migration.new(plugin_name, options)
    end
  end
end
