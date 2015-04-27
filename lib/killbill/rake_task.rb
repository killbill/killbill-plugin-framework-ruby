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
        gemfile_name = ENV['BUNDLE_GEMFILE'] || 'Gemfile'
        new(opts[:base_name] || Dir.pwd,                        # Path to the plugin root directory (where the gempec and/or Gemfile should be)
            opts[:plugin_name],                                 # Plugin name, e.g. 'klogger'
            opts[:gem_name],                                    # Gem file name, e.g. 'klogger-1.0.0.gem'
            opts[:gemfile_name] || gemfile_name,                # Gemfile name
            opts[:gemfile_lock_name] || "#{gemfile_name}.lock", # Gemfile.lock name
            opts[:verbose] || false)
        .install
      end
    end

    def initialize(base_name, plugin_name, gem_name, gemfile_name, gemfile_lock_name, verbose)
      @verbose = verbose

      @logger = Logger.new(STDOUT)
      @logger.formatter = proc do |severity, datetime, _, msg|
        date_format = datetime.strftime('%Y-%m-%d %H:%M:%S.%L')
        if severity == "INFO" || severity == "WARN"
          "KillBill [#{date_format}] #{severity}  : #{msg}\n"
        else
          "KillBill [#{date_format}] #{severity} : #{msg}\n"
        end
      end
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

      # Staging area to install the killbill.properties and config.ru files
      @plugin_root_target_dir = @package_dir.join("#{version}").expand_path

      # Staging area to install gem dependencies
      # Note the Killbill friendly structure (which we will keep in the tarball)
      @plugin_gem_target_dir = @package_dir.join("#{version}/gems").expand_path
    end

    def name
      @plugin_gemspec.name
    end

    def version
      @plugin_gemspec.version
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

        # desc added after tasks are defined by Rake::PackageTask see bellow
        task :package, [:verbose] => :stage # builds .tar.gz & .zip packages

        package_task = Rake::PackageTask.new(name, version) do |pkg|
          pkg.need_tar_gz = true
          pkg.need_zip = true
        end

        Rake::Task['package'].add_description "Package #{name} plugin #{version}"
        Rake::Task['repackage'].add_description "Re-package #{name} plugin #{version}"

        desc "Stage dependencies for #{name} plugin #{version}"
        task :stage, [:verbose] => :validate do |t, args|
          set_verbosity(args)

          stage_dependencies
          stage_extra_files

          # Small hack! Update the list of files to package (Rake::FileList is evaluated too early above)
          package_task.package_files = Rake::FileList.new("#{@package_dir.basename}/**/*")
        end

        desc "Deploy #{name} plugin #{version} to Kill Bill"
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
        task :dependencies => :validate do
          print_dependencies
        end
        task :dependency => :dependencies

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

    def bundler?; !! @gemfile_definition end

    def print_dependencies
      # NOTE: can be improved to include :git info and warn on gem :path
      specs.each { |spec| puts "  #{spec.name} (#{spec.version})" }
    end

    # Parse the <plugin_name>.gemspec file
    def find_plugin_gemspec
      gemspecs = @plugin_name ? [File.join(@base, "#{@plugin_name}.gemspec")] : Dir[File.join(@base, "{,*}.gemspec")]
      raise "Unable to find your plugin gemspec in #{@base}" if gemspecs.size == 0
      raise "Found multiple plugin gemspec in #{@base} : #{gemspecs.inspect}" if gemspecs.size > 1
      spec_path = gemspecs.first
      @logger.debug "Loading #{spec_path}"
      Gem::Specification.load(spec_path)
    end

    def find_plugin_gem(spec)
      gem_name = spec.file_name

      # Try in the base directory first
      plugin_gem_file = Pathname.new(gem_name).expand_path
      unless plugin_gem_file.file? # `rake build` (./pkg)
        plugin_gem_file = Pathname.new(File.join('pkg', gem_name))
      end

      unless plugin_gem_file.file?
        raise "Unable to find #{gem_name}. Did you build it? (`rake build')"
      end

      @logger.debug "Found #{plugin_gem_file}"
      plugin_gem_file.expand_path
    end

    def find_missing_gem(spec, silent = nil)
      base = nil
      if spec.loaded_from
        # spec.loaded_from is (usually) the path to the gemspec file
        base = Pathname.new(File.dirname(spec.loaded_from)).expand_path
        if ! base.file?
          base = nil unless base.directory?
        end
      end
      unless base
        base = spec.gems_dir if spec.respond_to?(:gems_dir)
        base = spec.base_dir if spec.respond_to?(:base_dir)
      end
      # might end-up with a slightly incorrect resolution (due Bundler) :
      # e.g. .../rvm/gems/jruby-1.7.19@global/gems/bundler-1.7.9/lib/bundler/gems
      if base
        parent = base
        parent = parent.parent while ! parent.join('cache').directory?
        base = parent if parent && parent.join('gems').directory? # RGs layout
      end

      gem_file = nil
      gem_name = spec.file_name
      gem_paths = Gem.paths.path.dup; gem_paths.unshift(base) if base
      gem_paths.each do |gem_path| # e.g. /opt/rvm/gems/jruby-1.7.16@global
        if File.directory? cache_dir = File.join(gem_path, 'cache')
          if File.file? gem_file = File.join(cache_dir, gem_name)
            gem_file = Pathname.new(gem_file); break
          else
            gem_file = nil
          end
        else
          gem_files = Dir[File.join(gem_path, "**/#{gem_name}")]
          unless gem_files.empty?
            @logger.debug "Gem candidates found: #{gem_files.inspect}"
            gem_file = Pathname.new(gem_files.first); break
          end
        end
      end

      if gem_file.nil? || ! gem_file.file?
        return nil if silent
        raise "Unable to find #{gem_name} under #{gem_paths.inspect}"
      end

      @logger.debug "Found #{gem_file}"
      gem_file.expand_path
    end

    # Parse the existing Gemfile and Gemfile.lock files
    def find_gemfile
      gemfile = gemfile_path
      # Don't make the Gemfile a requirement, a gemspec should be enough
      return nil unless gemfile.file?

      # Make sure the developer ran `bundle install' first. We could probably run
      #   Bundler::Installer::install(@plugin_gem_target_dir, @definition, {})
      # but it may be better to make sure all dependencies are resolved first,
      # before attempting to build the plugin
      gemfile_lock = gemfile_lock_path
      raise "Unable to find the Gemfile.lock at #{gemfile_lock} for your plugin. Please run `bundle install' first" unless gemfile_lock.file?

      @logger.debug "Parsing #{gemfile} and #{gemfile_lock}"
      Bundler::Definition.build(gemfile, gemfile_lock, nil)
    end

    def gemfile_path
      @base.join(@gemfile_name).expand_path
    end

    def gemfile_lock_path
      @base.join(@gemfile_lock_name).expand_path
    end

    def stage_dependencies
      # Create the target directory
      mkdir_p @plugin_gem_target_dir.to_s, :verbose => @verbose

      @logger.debug "Installing all gem dependencies to #{@plugin_gem_target_dir}"
      # We can't simply use Bundler::Installer unfortunately, because we can't tell it to copy the gems for cached ones
      # (it will default to using Bundler::Source::Path references to the gemspecs on "install").

      # part of copying the dependencies is getting Gemfile/Gemfile.lock in
      # otherwise :git => gem dependencies would need work-arounds to work
      if bundler?
        copy_gemfile # plugin gem build might re-copy, that's fine!
        generate_boot_rb if boot_rb_file.nil?
        # else user-suplied boot.rb will be copied into the package
      end

      specs.each do |spec|
        if ! gem_path = valid_gem_path(spec)
          if bundler?
            if gem_path == false # spec.name == name
              # Gemfile very likely declares gemspec ... so we need to get that in
              # yet the current way (the plugin gem must be built first) we can
              # not simply copy spec.loaded_from into the package's root directory
              # (the actual [PLUGIN_ROOT]/killbill-plugin.gemspec) as that depends
              # on `git' binary on PATH (to get the actual gem.files)
              @logger.info "Building #{spec.name} gem from #{spec.loaded_from}"
              plugin_gem = Gem::Package.new(spec.file_name)
              plugin_gem.spec = spec
              plugin_gem.build(true) # skip_validation
              gemspec_name = File.basename(spec.loaded_from)
              puts_to_root plugin_gem.spec.to_ruby, gemspec_name
              # NOTE: further the unpacked gemspec will be read by Bundler and assumes
              # the unpacked gem structure to be found on the file-system, extract :
              plugin_gem.extract_files @plugin_root_target_dir
            else # gem not under gem cache_dir (default gem or multiple gem paths)
              gem_path = find_missing_gem(spec)
              @logger.debug "Staging #{spec.name} (#{spec.version}) from #{gem_path}"
              do_install_gem(gem_path, spec)
            end
          else # mostly Bunder-less backwards-compatibility
            gem_path = find_missing_gem(spec, :silent) || find_plugin_gem(spec)
            @logger.info "Staging #{spec.full_name} from #{gem_path}"
            do_install_gem(gem_path, spec)
          end
        elsif gem_path.file?
          @logger.debug "Staging #{spec.name} (#{spec.version}) from #{gem_path}"
          do_install_gem(gem_path, spec)
        elsif gem_path.directory?
          @logger.debug "Staging #{spec.name} (#{spec.version}) from #{gem_path}"
          do_install_bundler(gem_path, spec)
        else
          raise "#{spec.name} gem path #{gem_path.inspect} does not exist"
        end
      end
    end

    def valid_gem_path(spec)
      cache_file = File.join(spec.cache_dir, "#{spec.full_name}.gem")
      cache_path = Pathname.new(cache_file).expand_path
      return cache_path if cache_path.file?
      if spec.source && bundler? && spec.source.is_a?(Bundler::Source)
        # Path < Source and Git < Path :
        case spec.source
        when Bundler::Source::Git
          # NOTE cache_path only works with `bundle cache --all`
          # when bundle cached install path points to cache
          #  e.g. ./vendor/cache/killbill-plugin-framework-ruby-ce5e19f45bc9
          # otherwise it's the path from under RG (as usual for Bundler)
          #  e.g. [RVM]/gems/jruby-1.7.19@kb/bundler/gems/killbill-plugin-framework-ruby-ce5e19f45bc9
          return spec.source.install_path
        when Bundler::Source::Path
          return false if spec.name == name # it's the plugin gem itself
          raise "gem #{spec.name}, :path => ... is not supported"
        end
      end
      nil
    end

    def do_install_bundler(path, spec)
      #full_gem_path = Pathname.new(spec.full_gem_path)

      #gem_relative_path = full_gem_path.relative_path_from(Bundler.install_path)
      #filenames = []; gem_relative_path.each_filename { |f| filenames << f }

      #exclude_gems = true
      #unless filenames.empty?
      #  full_gem_path = Pathname.new(Bundler.install_path) + filenames.first
      #  exclude_gems = false
      #end

      FileUtils.mkdir_p target_dir = File.join(@plugin_gem_target_dir, "bundler/gems")

      if spec.groups.include?(:killbill_excluded)
        Dir.glob("#{path}/**/#{spec.name}.gemspec").each do |file|
          gem_target_file = File.join(target_dir, File.basename(file))
          FileUtils.rm(gem_target_file) if File.exist?(gem_target_file)
          FileUtils.cp(file, target_dir) # gemspec only to avert Bundler error
        end
      else
        gem_target_dir = File.join(target_dir, File.basename(path))
        FileUtils.rm_r(gem_target_dir) if File.exist?(gem_target_dir)
        FileUtils.cp_r(path, target_dir)
        # the copied .git directory is not needed (might be large) :
        git_target_dir = File.join(gem_target_dir, '.git')
        FileUtils.rm_r(git_target_dir) if File.exist?(git_target_dir)
      end
    rescue => e
      @logger.warn "Unable to stage #{spec.name} from #{path}: #{e}"
      raise e
    end

    def do_install_gem(path, spec)
      name, version = spec.name, spec.version
      options = {
          :force       => true,
          :install_dir => @plugin_gem_target_dir,
          #:only_install_dir => true,
          # Should be redundant with the tweaks below
          :development => false,
          :wrappers    => true
      }
      if Gem::Installer.respond_to?(:at)
        gem_installer = Gem::Installer.at(path.to_s, options)
      else # constructing an Installer object with a string is deprecated
        gem_installer = Gem::Installer.new(path.to_s, options)
      end

      # Tweak the spec file as there are a lot of things we don't care about
      gem_installer.spec.executables      = nil
      gem_installer.spec.extra_rdoc_files = nil
      gem_installer.spec.test_files       = nil
      # avoid the annoying post_install_message from money gem (and others)
      gem_installer.spec.post_install_message = nil

      gem_installer.install
    rescue => e
      @logger.warn "Unable to stage #{name} (#{version}) from #{path}: #{e}"
      raise e
    end

    def generate_boot_rb
      @logger.debug "Generating boot.rb into #{@plugin_root_target_dir}"
      puts_to_root <<-END, 'boot.rb'
ENV["GEM_HOME"] = File.expand_path('gems', File.dirname(__FILE__))
ENV["GEM_PATH"] = ENV["GEM_HOME"]
# environment is set statically, as soon as Sinatra is loaded
ENV["RACK_ENV"] = 'production'
# previously the same WD was used dependent on server startup
Dir.chdir(File.dirname(__FILE__))
# prepare to boot using Bundler :
ENV["BUNDLE_WITHOUT"] ||= "#{ENV["BUNDLE_WITHOUT"] || 'development:test'}"
ENV["BUNDLE_GEMFILE"] ||= File.expand_path('Gemfile', File.dirname(__FILE__))
ENV["JBUNDLE_SKIP"] = 'true' # we only use JBundler for development/testing

require 'rubygems' unless defined? Gem
if File.exists?(ENV["BUNDLE_GEMFILE"])
  require 'bundler'; Bundler.setup
end
END
    end

    def copy_gemfile
      copy_to_root gemfile_path, 'Gemfile'
      copy_to_root gemfile_lock_path, 'Gemfile.lock'
    end

    def stage_extra_files
      unless boot_rb_file.nil?
        @logger.info "Staging (user-suplied) #{boot_rb_file}"
        copy_to_root boot_rb_file
      end
      unless killbill_properties_file.nil?
        @logger.debug "Staging #{killbill_properties_file}"
        copy_to_root killbill_properties_file
      end
      unless config_ru_file.nil?
        @logger.debug "Staging #{config_ru_file}"
        copy_to_root config_ru_file
      end
    end

    def copy_to_root(file_path, base_name = File.basename(file_path))
      target_file = File.join(@plugin_root_target_dir, base_name)
      cp file_path, target_file, :verbose => @verbose
    end

    def puts_to_root(content, base_name)
      target_file = File.join(@plugin_root_target_dir, base_name)
      File.open(target_file, 'w') { |file| file << content }
    end

    def boot_rb_file
      path_to_string @base.join("boot.rb").expand_path
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
