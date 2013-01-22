require 'bundler'
require 'logger'
require 'pathname'
require 'rake'
require 'rake/packagetask'

module Killbill
  class PluginHelper
    include Rake::DSL

    class << self
      def install_tasks(opts = {})
        new(opts[:base_name] || Dir.pwd,                # Path to the plugin root directory (where the gempec and/or Gemfile should be)
            opts[:target_dir_name] || "build",          # Temporary build directory
            opts[:name],                                # Plugin name, e.g. 'klogger'
            opts[:gem_name],                            # Gem file name, e.g. 'klogger-1.0.0.gem'
            opts[:gemfile_name] || "Gemfile",           # Gemfile name
            opts[:gemfile_lock_name] || "Gemfile.lock") # Gemfile.lock name
        .install
      end
    end

    def initialize(base_name, target_dir_name, name, gem_name, gemfile_name, gemfile_lock_name)
      @logger = Logger.new(STDOUT)
      #@logger.level = Logger::DEBUG

      # Plugin base directory
      @base         = Pathname.new(base_name).expand_path
      # Staging directory
      @target_dir   = Pathname.new(target_dir_name).expand_path

      @plugin_gemspec     = find_plugin_gemspec(name)
      @plugin_gem_file    = find_plugin_gem(gem_name)
      @gemfile_definition = find_gemfile(gemfile_name, gemfile_lock_name)
    end

    def specs
      # Rely on the Gemfile definition, if it exists, to get all dependencies
      # (we assume the Gemfile includes the plugin gemspec, as it should).
      # Otherwise, use only the plugin gemspec.
      @specs ||= @gemfile_definition ? @gemfile_definition.specs : [@plugin_gemspec]
    end

    def install
      namespace :killbill do
        desc "Stage all dependencies"
        task 'stage' do
          stage_dependencies
        end

        # Build the .tar.gz and .zip packages
        Rake::PackageTask.new(name, version) do |p|
          Rake::Task["stage"].invoke

          p.need_tar = true
          p.need_zip = true
          # TODO rename build to something else in the tar.gz/zip files
          p.package_files.include("#{@target_dir.basename}/**/*")
        end

        desc "List all dependencies"
        task 'dependency' do
          print_dependencies
        end
      end
    end

    private

    def print_dependencies
      puts "Gems to be staged:"
      specs.each { |spec| puts "  #{spec.name} (#{spec.version})" }
    end

    def name
      @plugin_gemspec.name
    end

    def version
      @plugin_gemspec.version
    end

    # Parse the <plugin_name>.gemspec file
    def find_plugin_gemspec(name = nil)
      gemspecs = name ? [File.join(@base, "#{name}.gemspec")] : Dir[File.join(@base, "{,*}.gemspec")]
      raise "Unable to find your plugin gemspec in #{@base}" unless gemspecs.size == 1
      spec_path = gemspecs.first
      @logger.debug "Parsing #{spec_path}"
      Bundler.load_gemspec(spec_path)
    end

    def find_plugin_gem(gem_name = nil)
      if gem_name
        # Absolute path?
        plugin_gem_file = Pathname.new(gem_name).expand_path
        # Relative path to the base?
        plugin_gem_file = @base.join(gem_name).expand_path unless plugin_gem_file.file?
        raise "Unable to find your plugin gem in #{@base}. Did you build it?" unless plugin_gem_file.file?
      else
        plugin_gem_files = Dir[File.join(@base, "**/#{name}-#{version}.gem")]
        @logger.debug "Gem candidates found: #{plugin_gem_files}"
        raise "Unable to find your plugin gem in #{@base}. Did you build it?" unless plugin_gem_files.size >= 1
        # Take the first one, assume the other ones are from build directories (e.g. pkg)
        plugin_gem_file = plugin_gem_files.first
      end

      @logger.debug "Found #{plugin_gem_file}"
      Pathname.new(plugin_gem_file).expand_path
    end

    # Parse the existing Gemfile and Gemfile.lock files
    def find_gemfile(gemfile_name, gemfile_lock_name)
      gemfile = @base.join(gemfile_name).expand_path
      # Don't make the Gemfile a requirement, a gemspec should be enough
      return nil unless gemfile.file?

      # Make sure the developer ran `bundle install' first. We could probably run
      #   Bundler::Installer::install(@target_dir, @definition, {})
      # but it may be better to make sure all dependencies are resolved first,
      # before attempting to build the plugin
      gemfile_lock = @base.join(gemfile_lock_name).expand_path
      raise "Unable to find the Gemfile.lock at #{gemfile_lock} for your plugin. Please run `bundle install' first" unless gemfile_lock.file?

      @logger.debug "Parsing #{gemfile} and #{gemfile_lock}"
      Bundler::Definition.build(gemfile, gemfile_lock, nil)
    end

    def stage_dependencies
      # Create the target directory
      Dir.mkdir @target_dir.to_s

      @logger.debug "Installing all gem dependencies to #{@target_dir}"
      # We can't simply use Bundler::Installer unfortunately, because we can't tell it to copy the gems for cached ones
      # (it will default to using Bundler::Source::Path references to the gemspecs on "install").
      specs.each do |spec|
        # For the plugin itself, install it manually (the cache path is likely to be wrong)
        next if spec.name == name and spec.version == version
        @logger.debug "Staging #{spec.name} (#{spec.version}) from #{spec.cache_file}"
        Gem::Installer.new(spec.cache_file, {:force => true, :install_dir => @target_dir}).install
      end

      @logger.debug "Staging #{name} (#{version}) from #{@plugin_gem_file}"
      Gem::Installer.new(@plugin_gem_file, {:force => true, :install_dir => @target_dir}).install
    end
  end
end

Killbill::PluginHelper.install_tasks
