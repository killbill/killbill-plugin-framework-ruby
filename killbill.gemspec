# coding: utf-8

Gem::Specification.new do |s|
  s.name        = 'killbill'

  path = File.expand_path('lib/killbill/version.rb', File.dirname(__FILE__))
  s.version = File.read(path).match( /.*VERSION\s*=\s*['"](.*)['"]/m )[1]

  s.summary     = 'Framework to write Kill Bill plugins in Ruby.'
  s.description = 'Base classes to write plugins.'

  s.required_ruby_version = '>= 1.9.3'

  s.license = 'Apache License (2.0)'

  s.author   = 'Kill Bill core team'
  s.email    = 'killbilling-users@googlegroups.com'
  s.homepage = 'http://killbill.io'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.bindir        = 'bin'
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']

  s.rdoc_options << '--exclude' << '.'

  s.add_dependency 'sinatra', '~> 1.3.4'
  s.add_dependency 'rack', '>= 1.5.2'
  s.add_dependency 'typhoeus', '~> 0.6.9'
  s.add_dependency 'tzinfo', '~> 1.2.0'
  # semi-optional:
  s.add_development_dependency 'thread_safe', '~> 0.3.4'
  s.add_development_dependency 'activerecord', '~> 4.1.0'
  if defined?(JRUBY_VERSION)
    s.add_development_dependency 'activerecord-bogacs', '~> 0.3'
    # See https://github.com/killbill/killbill-plugin-framework-ruby/issues/33
    s.add_development_dependency 'activerecord-jdbc-adapter', '~> 1.3'
    s.add_development_dependency 'jdbc-mariadb', '~> 1.1.8'
    s.add_development_dependency 'jdbc-postgres', '~> 9.4'
  end
  s.add_development_dependency 'actionpack', '~> 4.1.0'
  s.add_development_dependency 'actionview', '~> 4.1.0'
  s.add_development_dependency 'activemerchant', '~> 1.48.0'
  s.add_development_dependency 'offsite_payments', '~> 2.1.0'
  s.add_development_dependency 'monetize', '~> 1.1.0'
  s.add_development_dependency 'money', '~> 6.5.1'
  # testing/development :
  s.add_development_dependency 'jbundler', '~> 0.9.2'
  s.add_development_dependency 'rake', '>= 10.0.0', '< 11.0.0'
  s.add_development_dependency 'rspec', '~> 2.12.0'
  s.add_development_dependency 'thor', '~> 0.19.1'
  if defined?(JRUBY_VERSION)
    s.add_development_dependency 'jdbc-sqlite3', '~> 3.7'
  else
    s.add_development_dependency 'sqlite3', '~> 1.3.7'
  end
end
