require 'bundler'
require 'logger'
require 'pathname'
require 'rake'
require 'rake/packagetask'
require 'rubygems/installer'

module Killbill
  class PluginHelper
    include Rake::DSL

    class << self
      def install_tasks(opts = {})
        new(opts[:base_name] || Dir.pwd,                # Path to the plugin root directory (where the gempec and/or Gemfile should be)
            opts[:plugin_name],                         # Plugin name, e.g. 'klogger'
            opts[:gem_name],                            # Gem file name, e.g. 'klogger-1.0.0.gem'
            opts[:gemfile_name] || "Gemfile",           # Gemfile name
            opts[:gemfile_lock_name] || "Gemfile.lock", # Gemfile.lock name
            opts[:verbose] || false)
        .install
      end
    end

    def initialize(base_name, plugin_name, gem_name, gemfile_name, gemfile_lock_name, verbose)
      @verbose = verbose

      @logger = Logger.new(STDOUT)
      @logger.level = @verbose ? Logger::DEBUG : Logger::INFO

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

      # Staging area to install the killbill.properties and config.ru files
      @plugin_root_target_dir = @package_dir.join("#{version}").expand_path
    end

    def specs
      # Rely on the Gemfile definition, if it exists, to get all dependencies
      # (we assume the Gemfile includes the plugin gemspec, as it should).
      # Otherwise, use only the plugin gemspec.
      # When using the Gemfile definition, don't include the :development group -- should this be configurable?
      @specs ||= @gemfile_definition ? @gemfile_definition.specs_for([:default]) : [@plugin_gemspec]
    end

    def install
      namespace :killbill do
        desc "Validate plugin tree"
        # The killbill.properties file is required, but not the config.ru one
        task :validate, [:verbose] => killbill_properties_file do |t, args|
          set_verbosity(args)
          validate
        end

        # Build the .tar.gz and .zip packages
        task :package, [:verbose] => :stage
        package_task = Rake::PackageTask.new(name, version) do |p|
          p.need_tar_gz = true
          p.need_zip = true
        end

        desc "Stage all dependencies"
        task :stage, [:verbose] => :validate do |t, args|
          set_verbosity(args)

          stage_dependencies
          stage_extra_files

          # Small hack! Update the list of files to package (Rake::FileList is evaluated too early above)
          package_task.package_files = Rake::FileList.new("#{@package_dir.basename}/**/*")
        end

        desc "Deploy the plugin to Kill Bill"
        task :deploy, [:force, :plugin_dir, :verbose] => :stage do |t, args|
          set_verbosity(args)

          plugins_dir = Pathname.new("#{args.plugin_dir || '/var/tmp/bundles/plugins/ruby'}").expand_path
          mkdir_p plugins_dir, :verbose => @verbose

          plugin_path = Pathname.new("#{plugins_dir}/#{name}")
          if plugin_path.exist?
            if args.force == "true"
              @logger.info "Deleting previous plugin deployment #{plugin_path}"
              rm_rf plugin_path, :verbose => @verbose
            else
              raise "Cowardly not deleting previous plugin deployment #{plugin_path} - override with rake killbill:deploy[true]"
            end
          end

          cp_r @package_dir, plugins_dir, :verbose => @verbose

          Rake::FileList.new("#{@base}/*.yml").each do |config_file|
            config_file_path = Pathname.new("#{plugin_path}/#{version}/#{File.basename(config_file)}").expand_path
            @logger.info "Deploying #{config_file} to #{config_file_path}"
            cp config_file, config_file_path, :verbose => @verbose
          end
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

    def set_verbosity(args)
      return unless args.verbose == 'true'
      @verbose = true
      @logger.level = Logger::DEBUG
    end

    def validate
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

    def find_plugin_gem(spec)
      gem_name = spec.file_name
      # spec.loaded_from is the path to the gemspec file
      if spec.loaded_from # will likely be nil for the plugin's gemspec
        base = Pathname.new(File.dirname(spec.loaded_from)).expand_path
      else
        base = nil
      end

      # Try in the base directory first
      plugin_gem_file = Pathname.new(gem_name).expand_path
      if base && ! plugin_gem_file.file?
        plugin_gem_file = base.join(gem_name).expand_path
      end
      unless plugin_gem_file.file? # `rake build` (./pkg)
        plugin_gem_file = Pathname.new(File.join('pkg', gem_name))
      end

      unless plugin_gem_file.file?
        gem_paths = Gem.paths.path.dup; gem_paths.unshift(base) if base
        # NOTE: in case it's the plugin.gem not sure if this makes sense
        gem_paths.each do |gem_path| # e.g. /opt/rvm/gems/jruby-1.7.16@global
          if File.directory? cache_dir = File.join(gem_path, 'cache')
            if File.file? gem_file = File.join(cache_dir, gem_name)
              plugin_gem_file = Pathname.new(gem_file); break
            end
          else
            gem_files = Dir[File.join(gem_path, "**/#{gem_name}")]
            unless gem_files.empty?
              @logger.debug "Gem candidates found: #{gem_files.inspect}"
              plugin_gem_file = Pathname.new(gem_files.first); break
            end
          end
        end
      end

      unless plugin_gem_file.file?
        raise "Unable to find #{gem_name} in #{base}. Did you build it? (`rake build')"
      end

      @logger.debug "Found #{plugin_gem_file}"
      plugin_gem_file.expand_path
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
      mkdir_p @target_dir.to_s, :verbose => @verbose

      @logger.debug "Installing all gem dependencies to #{@target_dir}"
      # We can't simply use Bundler::Installer unfortunately, because we can't tell it to copy the gems for cached ones
      # (it will default to using Bundler::Source::Path references to the gemspecs on "install").
      specs.each do |spec|
        plugin_gem_file = Pathname.new(spec.cache_file).expand_path
        if plugin_gem_file.file?
          @logger.debug "Staging #{spec.name} (#{spec.version}) from #{plugin_gem_file}"
        else
          plugin_gem_file = find_plugin_gem(spec)
          @logger.info "Staging custom gem #{spec.full_name} from #{plugin_gem_file}"
        end

        do_install_gem(plugin_gem_file, spec.name, spec.version)
      end
    end

    def do_install_gem(path, name, version)
      gem_installer                       = Gem::Installer.new(path,
                                                               {
                                                                   :force       => true,
                                                                   :install_dir => @target_dir,
                                                                   # Should be redundant with the tweaks below
                                                                   :development => false,
                                                                   :wrappers    => true
                                                               })

      # Tweak the spec file as there are a lot of things we don't care about
      gem_installer.spec.executables      = nil
      gem_installer.spec.extensions       = nil
      gem_installer.spec.extra_rdoc_files = nil
      gem_installer.spec.test_files       = nil

      gem_installer.install
    rescue => e
      @logger.warn "Unable to stage #{name} (#{version}) from #{path}: #{e}"
      raise e
    end

    def stage_extra_files
      unless killbill_properties_file.nil?
        @logger.debug "Staging #{killbill_properties_file} to #{@plugin_root_target_dir}"
        cp killbill_properties_file, @plugin_root_target_dir, :verbose => @verbose
      end
      unless config_ru_file.nil?
        @logger.debug "Staging #{config_ru_file} to #{@plugin_root_target_dir}"
        cp config_ru_file, @plugin_root_target_dir, :verbose => @verbose
      end
    end

    def killbill_properties_file
      path_to_string @base.join("killbill.properties").expand_path
    end

    def config_ru_file
      path_to_string @base.join("config.ru").expand_path
    end

    def path_to_string(path)
      path.file? ? path.to_s : nil
    end
  end
end
