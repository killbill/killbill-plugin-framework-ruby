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
            opts[:plugin_name],                         # Plugin name, e.g. 'klogger'
            opts[:gem_name],                            # Gem file name, e.g. 'klogger-1.0.0.gem'
            opts[:gemfile_name] || "Gemfile",           # Gemfile name
            opts[:gemfile_lock_name] || "Gemfile.lock") # Gemfile.lock name
        .install
      end
    end

    def initialize(base_name, plugin_name, gem_name, gemfile_name, gemfile_lock_name)
      @logger = Logger.new(STDOUT)
      #@logger.level = Logger::DEBUG

      @base_name = base_name
      @plugin_name = plugin_name
      @gem_name = gem_name
      @gemfile_name = gemfile_name
      @gemfile_lock_name = gemfile_lock_name

      # Plugin base directory
      @base = Pathname.new(@base_name).expand_path

      # Find the gemspec to determine name and version
      @plugin_gemspec = find_plugin_gemspec

      # Temporary build directory
      # Don't use 'pkg' as it is used by Rake::PackageTask already: it will
      # hard link all files from @package_dir to pkg to avoid tar'ing up symbolic links
      @package_dir = Pathname.new(name).expand_path

      # Staging area to install gem dependencies
      # Note the Killbill friendly structure (which we will keep in the tarball)
      @target_dir = @package_dir.join("#{version}/gems").expand_path
    end

    def specs
      # Rely on the Gemfile definition, if it exists, to get all dependencies
      # (we assume the Gemfile includes the plugin gemspec, as it should).
      # Otherwise, use only the plugin gemspec.
      @specs ||= @gemfile_definition ? @gemfile_definition.specs : [@plugin_gemspec]
    end

    def install
      namespace :killbill do
        desc "Validate plugin tree"
        task :validate do
          validate
        end

        # Build the .tar.gz and .zip packages
        task :package => :stage
        package_task = Rake::PackageTask.new(name, version) do |p|
          p.need_tar_gz = true
          p.need_zip = true
        end

        desc "Stage all dependencies"
        task :stage => :validate do
          stage_dependencies

          # Small hack! Update the list of files to package (Rake::FileList is evaluated too early above)
          package_task.package_files = Rake::FileList.new("#{@package_dir.basename}/**/*")
        end

        desc "List all dependencies"
        task :dependency => :validate do
          print_dependencies
        end

        desc "Delete #{@package_dir}"
        task :clean => :clobber_package do
          rm_rf @package_dir
        end
      end
    end

    private

    def validate
      @plugin_gem_file    = find_plugin_gem
      @gemfile_definition = find_gemfile
    end

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
    def find_plugin_gemspec
      gemspecs = @plugin_name ? [File.join(@base, "#{@plugin_name}.gemspec")] : Dir[File.join(@base, "{,*}.gemspec")]
      raise "Unable to find your plugin gemspec in #{@base}" unless gemspecs.size == 1
      spec_path = gemspecs.first
      @logger.debug "Parsing #{spec_path}"
      Bundler.load_gemspec(spec_path)
    end

    def find_plugin_gem
      if @gem_name
        # Absolute path?
        plugin_gem_file = Pathname.new(@gem_name).expand_path
        # Relative path to the base?
        plugin_gem_file = @base.join(@gem_name).expand_path unless plugin_gem_file.file?
        raise "Unable to find your plugin gem in #{@base}. Did you build it (`rake build')?" unless plugin_gem_file.file?
      else
        plugin_gem_files = Dir[File.join(@base, "**/#{name}-#{version}.gem")]
        @logger.debug "Gem candidates found: #{plugin_gem_files}"
        raise "Unable to find your plugin gem in #{@base}. Did you build it? (`rake build')" unless plugin_gem_files.size >= 1
        # Take the first one, assume the other ones are from build directories (e.g. pkg)
        plugin_gem_file = plugin_gem_files.first
      end

      @logger.debug "Found #{plugin_gem_file}"
      Pathname.new(plugin_gem_file).expand_path
    end

    # Parse the existing Gemfile and Gemfile.lock files
    def find_gemfile
      gemfile = @base.join(@gemfile_name).expand_path
      # Don't make the Gemfile a requirement, a gemspec should be enough
      return nil unless gemfile.file?

      # Make sure the developer ran `bundle install' first. We could probably run
      #   Bundler::Installer::install(@target_dir, @definition, {})
      # but it may be better to make sure all dependencies are resolved first,
      # before attempting to build the plugin
      gemfile_lock = @base.join(@gemfile_lock_name).expand_path
      raise "Unable to find the Gemfile.lock at #{gemfile_lock} for your plugin. Please run `bundle install' first" unless gemfile_lock.file?

      @logger.debug "Parsing #{gemfile} and #{gemfile_lock}"
      Bundler::Definition.build(gemfile, gemfile_lock, nil)
    end

    def stage_dependencies
      # Create the target directory
      mkdir_p @target_dir.to_s

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
