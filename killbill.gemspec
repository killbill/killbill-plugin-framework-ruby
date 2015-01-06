version = File.read(File.expand_path('../VERSION', __FILE__)).strip

Gem::Specification.new do |s|
  s.name        = 'killbill'
  s.version     = version
  s.summary     = 'Framework to write Kill Bill plugins in Ruby.'
  s.description = 'Base classes to write plugins.'

  s.required_ruby_version = '>= 1.9.3'

  s.license = 'Apache License (2.0)'

  s.author   = 'Kill Bill core team'
  s.email    = 'killbilling-users@googlegroups.com'
  s.homepage = 'http://kill-bill.org'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.bindir        = 'bin'
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.rdoc_options << '--exclude' << '.'

  s.add_dependency 'sinatra', '~> 1.3.4'
  s.add_dependency 'typhoeus', '~> 0.6.9'
  s.add_dependency 'tzinfo', '~> 1.2.0'

  s.add_development_dependency 'thread_safe', '~> 0.3.4'
  s.add_development_dependency 'activerecord', '~> 4.1.0'
  s.add_development_dependency 'activerecord-bogacs', '~> 0.2.0'
  if defined?(JRUBY_VERSION)
    s.add_development_dependency 'activerecord-jdbcmysql-adapter', '~> 1.3.12'
    s.add_development_dependency 'activerecord-jdbcsqlite3-adapter', '~> 1.3.12'
  else
    s.add_development_dependency 'sqlite3', '~> 1.3.7'
  end
  s.add_development_dependency 'actionpack', '~> 4.1.0'
  s.add_development_dependency 'actionview', '~> 4.1.0'
  s.add_development_dependency 'activemerchant', '~> 1.44.1'
  s.add_development_dependency 'offsite_payments', '~> 2.0.1'
  s.add_development_dependency 'monetize', '~> 0.3.0'
  s.add_development_dependency 'money', '~> 6.1.1'
  s.add_development_dependency 'jbundler', '~> 0.4.3'
  s.add_development_dependency 'rack', '>= 1.5.2'
  s.add_development_dependency 'rake', '>= 0.8.7'
  s.add_development_dependency 'rspec', '~> 2.12.0'
  s.add_development_dependency 'thor', '~> 0.19.1'

  s.requirements << "jar 'org.kill-bill.billing:killbill-api'"
  # For testing only
  s.requirements << "jar 'org.kill-bill.billing:killbill-util:tests'"
end
