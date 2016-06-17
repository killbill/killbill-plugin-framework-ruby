require 'bundler'
require 'logger'
require 'pathname'
require 'tmpdir'
require 'rake'
require 'rubygems/installer'

module Killbill
  class PluginHelper
    include Rake::DSL

    class << self
      def install_tasks(opts = {})
        gemfile_name = ENV['BUNDLE_GEMFILE'] || 'Gemfile'
        new(opts[:base_name] || Dir.pwd,          # Path to the plugin root directory (where the gempec and/or Gemfile should be)
            opts[:plugin_name],                   # Plugin name, e.g. 'klogger'
            opts[:gem_name],                      # Gem file name, e.g. 'klogger-1.0.0.gem'
            opts[:gemfile_name] || gemfile_name,  # Gemfile name
            opts[:gemfile_lock_name] || "#{gemfile_name}.lock",
            opts.key?(:verbose) ? opts[:verbose] : ENV['VERBOSE'] == 'true')
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
      @plugin_gemspec = load_plugin_gemspec

      @package_dir = Pathname.new('pkg').expand_path
      FileUtils.mkdir_p @package_dir
      # Temporary build directory
      # will hard link all files from @package_tmp_dir to pkg to avoid tar'ing
      # up symbolic links (similar to how Rake::PackageTask does prepare files)
      @package_tmp_dir = Pathname.new(File.join('tmp', name)).expand_path

      @root_dir_path = 'ROOT' # plugin's ROOT directory
      @gems_dir_path = File.join(@root_dir_path, 'gems')
      # Staging area to install the killbill.properties and config.ru files
      @plugin_target_dir = @package_tmp_dir.join("#{version}").expand_path
      @plugin_root_target_dir = @plugin_target_dir.join(@root_dir_path)

      # Staging area to install gem dependencies
      # Note the Killbill friendly structure (which we will keep in the tarball)
      @plugin_gem_target_dir = @plugin_target_dir.join(@gems_dir_path)
    end

    attr_reader :base

    def name
      @plugin_gemspec.name
    end

    def version
      @plugin_gemspec.version
    end

    def specs
      # Rely on the Gemfile definition, if it exists, to get all dependencies
      # (we assume the Gemfile includes the plugin gemspec, as it should).
      # Otherwise, use recursively retrieve the plugin gemspec' runtime dependencies
      # ... resolves all gems as they are currently installed with RubyGems
      @specs ||=
        if @gemfile_definition
          # don't include the :development group
          @gemfile_definition.specs_for([:default])
        else
          get_dependencies = lambda do |spec|
            deps = ( spec.runtime_dependencies || [] ).map(&:to_spec)
            deps.dup.each { |spec| deps += get_dependencies.call(spec) }
            deps.uniq
          end
          all_dependencies = get_dependencies.call(@plugin_gemspec)
          all_dependencies.dup.each do |spec|
            next unless all_dependencies.include?(spec) # removed previously

            # duplicate gemspec of same name might get included since we did
            # not really do through the gem activation hustle, lowest version
            # should win since those tend to be matched by strict requirements
            if other_spec = all_dependencies.find { |s| s.name == spec.name && s != spec }
              if other_spec.version > spec.version
                @logger.debug "Discarding matched gem '#{spec.name}' version #{other_spec.version} in favor of #{spec.version}"
                all_dependencies.delete(other_spec)
              else # other_spec.version < spec.version
                @logger.debug "Discarding matched gem '#{spec.name}' version #{spec.version} in favor of #{other_spec.version}"
                all_dependencies.delete(spec)
              end
            end
          end
          [ @plugin_gemspec ] + all_dependencies
        end
    end

    def install
      namespace :killbill do
        desc "Validate plugin tree"
        # The killbill.properties file is required, but not the config.ru one
        task :validate, [:verbose] => killbill_properties_file do |t, args|
          set_verbosity(args)
          validate
        end

        desc "Build all package files for #{name} plugin #{version}"
        task :package, [:verbose] => :stage # builds .tar.gz & .zip packages

        package_name = "#{name}-#{version}"
        package_dir = @package_dir.realpath # pkg
        package_dir_path = File.join(package_dir, package_name) # pkg/killbill-xxx-0.1.2

        task :package => [ tar_gz_file = File.join(package_dir, "#{package_name}.tar.gz") ]
        file tar_gz_file => [ package_dir_path, 'package:files' ] do
          chdir(package_dir) do
            tar_command = 'tar'
            sh tar_command, "zcvf", tar_gz_file, package_name
          end
        end

        task :package => [ zip_file = File.join(package_dir, "#{package_name}.zip") ]
        file zip_file => [ package_dir_path, 'package:files' ] do
          chdir(package_dir) do
            zip_command = 'zip'
            sh zip_command, "-r", zip_file, package_name
          end
        end

        directory package_dir_path
        task 'package:files' do
          # move files from tmp directory to pkg (based on how rake does)
          basename = Regexp.escape(@package_tmp_dir.basename.to_s)
          tmp_path = @package_tmp_dir.realpath.to_s
          realpath_tmp_prefix = tmp_path.sub(/\/#{basename}$/, '')
          package_files = Rake::FileList.new("#{tmp_path}/**/*")

          package_files.each do |fn|
            f = File.join(package_dir_path, fn.sub(realpath_tmp_prefix, ''))
            fdir = File.dirname(f)
            mkdir_p(fdir) unless File.exist?(fdir)
            if File.directory?(fn)
              mkdir_p(f)
            else
              rm_f f
              safe_ln(fn, f)
            end
          end
        end

        desc "Force a rebuild of package files for #{name} plugin #{version}"
        task :repackage => [:clobber_package, :package]

        task :clobber_tmp do
          rm_r @package_tmp_dir rescue nil
        end

        desc "Remove package files from #{@package_dir}"
        task :clobber_package do
          rm_f tar_gz_file if File.exist?(tar_gz_file)
          rm_f zip_file if File.exist?(zip_file)
          rm_r package_dir_path rescue nil
        end
        task :clobber => [:clobber_tmp, :clobber_package]

        task 'stage:init' do
          # NOOP task for plugins to hook up if they need some sort of initialization
          #  (task will be run in the context of the Killbill::PluginHelper instance)
          # NOTE: no need for post (stage:done) hook since it's easy using Rake :
          #  Rake::Task["killbill:package"].enhance { ... }
        end

        desc "Stage dependencies for #{name} plugin #{version}"
        task :stage, [:verbose] => [ :validate, 'stage:init' ] do |t, args|
          set_verbosity(args)

          mkdir_p @plugin_target_dir.to_s, :verbose => @verbose

          stage_dependencies
          stage_extra_files
        end

        desc "Deploy #{name} plugin #{version} to KillBill server"
        task :deploy, [:force, :plugin_dir, :verbose] => :stage do |t, args|
          plugins_dir = prepare_deploy(t, args)

          cp_r @package_tmp_dir, plugins_dir, :verbose => @verbose

          deploy_config_files plugin_path(plugins_dir) # .../[name]/[version]
        end

        desc "Deploy plugin in development mode (without staging)"
        task 'deploy:dev', [:force, :plugin_dir, :verbose] => :validate do |t, args|
          raise 'development deployment only works with Bundler' unless bundler?

          plugins_dir = prepare_deploy(t, args)

          # prepare "temporary" deployment at tmp/deploy:dev
          package_tmp_dir = Pathname.new(File.join('tmp', 'deploy:dev')).expand_path
          rm_r package_tmp_dir if File.exist?(package_tmp_dir)
          mkdir_p package_tmp_dir.to_s, :verbose => @verbose

          mkdir target_dir = package_tmp_dir.join(version.to_s)

          # NOTE: although same _boot.rb_ as with regular deploys might not work
          stage_extra_files target_dir
          if boot_rb_file.nil?
            generate_dev_boot_rb target_dir
          else
            @logger.info "Make sure the suplied #{boot_rb_file} is removed/adjusted before doing a regular killbill:deploy (same boot.rb won't likely work)"
          end

          # here we assume Gemfile declares gemspec and we link ROOT to base :
          ln_s @base, target_dir.join(@root_dir_path), :verbose => @verbose

          # ln -s /var/tmp/bundles/plugins/ruby/killbill-xxx -> tmp/deploy:dev
          ln_s package_tmp_dir, plugins_dir.join(name), :verbose => @verbose

          deploy_config_files target_dir
        end

        desc "List all dependencies"
        task :dependencies => :validate do
          print_dependencies
        end
        task :dependency => :dependencies

        desc "Delete #{@package_dir}"
        task :clean => :clobber do
          rm_r @package_dir if File.exist?(@package_dir)
        end

        namespace :db do
          desc 'Display the current migration version'
          task :current_version do
            puts migration.current_version
          end

          desc 'Display the migration SQL'
          task :sql_for_migration do
            puts migration.sql_for_migration.join("\n")
          end

          desc 'Run all migrations'
          task :migrate do
            migration.migrate
          end

          desc 'Dump the current schema structure (Ruby)'
          task :ruby_dump do
            puts migration.ruby_dump.string
          end

          desc 'Dump the current schema structure (SQL)'
          task :sql_dump do
            puts migration.sql_dump.string
          end
        end
      end
    end

    private

    def migration
      require 'killbill/migration'
      @migration ||= Killbill::Migration.new(@plugin_name || ENV['PLUGIN_NAME'])
    end

    def plugin_path(plugins_dir, versioned = true)
      plugin_path = plugins_dir.join(name)
      versioned ? plugin_path.join(version.to_s) : plugin_path
    end

    # (shared) deploy task(s) helper
    # @return _plugins_ directory
    def prepare_deploy(t, args)
      set_verbosity(args)

      plugins_dir = Pathname.new("#{args.plugin_dir || '/var/tmp/bundles/plugins/ruby'}").expand_path
      mkdir_p plugins_dir, :verbose => @verbose

      plugin_path = plugin_path(plugins_dir, false) # "#{plugins_dir}/#{name}"
      if plugin_path.exist?
        if args.force == "true"
          safe_unlink plugin_path # if link (deploy:dev) just remove the link
          if plugin_path.exist?
            @logger.info "Deleting previous plugin deployment #{plugin_path}"
            rm_rf plugin_path, :verbose => @verbose if plugin_path.exist?
          else
            @logger.info "Unlinked previous plugin deployment #{plugin_path}"
          end
        else
          raise "Cowardly not deleting previous plugin deployment #{plugin_path} - override with rake #{t.name}[true]"
        end
      end
      plugins_dir
    end

    # (shared) deploy task(s) helper
    def deploy_config_files(path, config_files = Rake::FileList.new("#{@base}/*.yml"))
      config_files.each do |config_file|
        config_file_path = File.join(path, File.basename(config_file))
        @logger.info "Deploying #{config_file} to #{config_file_path}"
        cp config_file, config_file_path, :verbose => @verbose
      end
    end

    def set_verbosity(args)
      return unless args.verbose == 'true'
      @verbose = true
      @logger.level = Logger::DEBUG
    end

    def validate
      if @gemfile_definition = build_gemfile
        @gemfile_definition.resolve
      end
      true
    end

    def bundler?; !! @gemfile_definition end

    def print_dependencies
      # NOTE: can be improved to include :git info and warn on gem :path
      specs.each { |spec| puts "  #{spec.name} (#{spec.version})" }
    end

    # Parse the <plugin_name>.gemspec file
    def load_plugin_gemspec
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
    def build_gemfile
      gemfile = gemfile_path
      # Don't make the Gemfile a requirement, a gemspec should be enough
      return nil unless gemfile.file?

      # Make sure the developer ran `bundle install' first. We could probably run
      #   Bundler::Installer::install(@plugin_gem_target_dir, @definition, {})
      # but it may be better to make sure all dependencies are resolved first,
      # before attempting to build the plugin
      gemfile_lock = gemfile_lock_path
      raise "Unable to find the bundle .lock at #{gemfile_lock} for your plugin. Please run `bundle install' first" unless gemfile_lock.file?

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

      generate_boot_rb if boot_rb_file.nil?
      # else user-suplied boot.rb will be copied into the package

      # part of copying the dependencies is getting Gemfile/Gemfile.lock in
      # otherwise :git => gem dependencies would need work-arounds to work
      copy_gemfile if bundler? # plugin gem build might re-copy, that's fine!

      specs.each do |spec|
        if ! gem_path = valid_gem_path(spec)
          if gem_path == false # spec.name == name
            # Gemfile very likely declares gemspec ... so we need to get that in
            # yet the current way (the plugin gem must be built first) we can
            # not simply copy spec.loaded_from into the package's root directory
            # (the actual [PLUGIN_ROOT]/killbill-plugin.gemspec) as that depends
            # on `git' binary on PATH (to get the actual gem.files)
            @logger.info "Building #{spec.name} gem from #{spec.loaded_from}"
            Dir.mktmpdir do |dir|
              plugin_gem = Gem::Package.new(File.join(dir, spec.file_name))
              plugin_gem.spec = spec
              plugin_gem.build(true) # skip_validation
              gemspec_name = File.basename(spec.loaded_from)
              puts_to_root plugin_gem.spec.to_ruby, gemspec_name
              # NOTE: further the unpacked gemspec will be read by Bundler and assumes
              # the unpacked gem structure to be found on the file-system, extract :
              plugin_gem.extract_files @plugin_root_target_dir
            end
            next
          end
          if bundler?
            # gem not under gem cache_dir (default gem or multiple gem paths)
            gem_path = find_missing_gem(spec)
            @logger.debug "Staging #{spec.name} (#{spec.version}) from #{gem_path}"
            do_install_gem(gem_path, spec)
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
      return false if spec.name == name # it's the plugin gem itself

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
          @logger.warn "gem '#{spec.name}' declares :path => '#{spec.source.path}' packaging will only work locally (while the path exists) !"
          return spec.source.path
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

    def generate_boot_rb(target_dir = @plugin_target_dir)
      @logger.debug "Generating boot.rb into #{target_dir}"
      # NOTE: previously the same WD was used dependent on server startup
      puts_to target_dir, <<-END, 'boot.rb'
Dir.chdir File.expand_path('#{@root_dir_path}', File.dirname(__FILE__))

ENV["GEM_HOME"] = File.join(File.dirname(__FILE__), '#{@gems_dir_path}')
ENV["GEM_PATH"] = ENV["GEM_HOME"]
# environment is set statically, as soon as Sinatra is loaded
ENV["RACK_ENV"] = 'production'
# prepare to boot using Bundler :
ENV["BUNDLE_WITHOUT"] = "#{ENV["BUNDLE_WITHOUT"] || 'development:test'}"
ENV["BUNDLE_GEMFILE"] = File.expand_path('Gemfile')
ENV["JBUNDLE_SKIP"] = 'true' # we only use JBundler for development/testing

require 'rubygems' unless defined? Gem
if File.exists?(ENV["BUNDLE_GEMFILE"])
  require 'bundler'; Bundler.setup
else
  #{adjust_plugin_load_path}
end

# try loading killbill (Bunler-less deploys or in case plugin forgot to require)
begin
  require 'killbill'
rescue LoadError => e # not fatal for un-usual cases where plugins vendor the gem
  warn "WARN: failed to load killbill gem: \#\{e.inspect\}"
end

#{plugin_require_line}

END
    end

    def generate_dev_boot_rb(target_dir, env = 'production')
      @logger.debug "Generating (dev) boot.rb into #{target_dir}"
      puts_to target_dir, <<-END, 'boot.rb'
Dir.chdir File.expand_path('#{@root_dir_path}', File.dirname(__FILE__))

ENV["GEM_HOME"] = '#{Gem.paths.home}'
ENV["GEM_PATH"] = '#{Gem.paths.path.join(':')}'
# environment is set statically, as soon as Sinatra is loaded
ENV["RACK_ENV"] = '#{env}'
# prepare to boot using Bundler :
ENV["BUNDLE_WITHOUT"] = "#{ENV["BUNDLE_WITHOUT"] || ''}"
ENV["BUNDLE_GEMFILE"] = File.expand_path('Gemfile')

require 'rubygems' unless defined? Gem
require 'bundler'; Bundler.setup

# require 'killbill'

#{plugin_require_line}

END
    end

    def plugin_require_line
      files = @plugin_gemspec.files; require_path = "#{@plugin_gemspec.require_path}/"
      files = files.select { |file| file.start_with?(require_path) && file[-3..-1] == '.rb' }
      # [ "lib/stripe.rb", "lib/stripe/api.rb", "lib/stripe/application.rb", ... ]
      files.map! { |file| file.sub(require_path, '') }
      # [ "stripe.rb", "stripe/api.rb", "stripe/application.rb", ... ]

      # 0. if killbill-stripe gem name has a killbill-stripe.rb use it
      return "require '#{name}'" if files.include?("#{name}.rb")

      # 1. RG convention: killbill-stripe -> require 'killbill/stripe'
      filename = "#{name.sub('-', '/')}"
      return "require '#{filename}'" if files.include?("#{filename}.rb")

      # 2. killbill-paypal-express -> require 'paypal-express' (not used)
      filename = "#{name.sub(/^killbill\-/, '')}"
      return "require '#{filename}'" if files.include?("#{filename}.rb")

      # 3. killbill-paypal-express -> require 'paypal_express'
      filename = filename.sub('-', '_')
      return "require '#{filename}'" if files.include?("#{filename}.rb")

      # not likely to happen - fallback to root file (warn when multiple) :
      files = files.select { |file| file.index('/').nil? }
      return "require '#{files[0]}'" if files.size == 1

      raise "could not resolve main require file from gemspec,\n please follow our naming convention for the bootstrap require e.g. \"#{name.sub('-', '/')}.rb\""
    end

    def adjust_plugin_load_path
      # NOTE: assuming Dir.chdir [ROOT]
      @plugin_gemspec.require_paths.map do |path|
        "$LOAD_PATH << File.expand_path('#{path}')" # $LOAD_PATH << 'lib'
      end.join('; ')
    end

    def copy_gemfile(target_dir = @plugin_root_target_dir)
      copy_to target_dir, gemfile_path, 'Gemfile'
      copy_to target_dir, gemfile_lock_path, 'Gemfile.lock'
    end

    def stage_extra_files(target_dir = @plugin_target_dir)
      unless boot_rb_file.nil?
        @logger.info "Staging (user-suplied) #{boot_rb_file}"
        copy_to target_dir, boot_rb_file
      end
      unless killbill_properties_file.nil?
        @logger.debug "Staging #{killbill_properties_file}"
        copy_to target_dir, killbill_properties_file
      end
      unless config_ru_file.nil?
        @logger.debug "Staging #{config_ru_file}"
        copy_to target_dir, config_ru_file
      end
    end

    def copy_to(target_dir, file_path, base_name = File.basename(file_path))
      target_file = File.join(target_dir, base_name)
      cp file_path, target_file, :verbose => @verbose
    end

    def puts_to(target_dir, content, base_name)
      target_file = File.join(target_dir, base_name)
      File.open(target_file, 'w') { |file| file << content }
    end

    def puts_to_base(content, base_name)
      target_file = File.join(@plugin_target_dir, base_name)
      File.open(target_file, 'w') { |file| file << content }
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
