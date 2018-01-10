version = File.read(File.expand_path('../VERSION', __FILE__)).strip

Gem::Specification.new do |s|
  s.name        = 'killbill-<%= identifier %>'
  s.version     = version
  s.summary     = 'Plugin to use <%= class_name %> as a gateway.'
  s.description = 'Kill Bill payment plugin for <%= class_name %>.'

  s.required_ruby_version = '>= 1.9.3'

  s.license = 'Apache License (2.0)'

  s.author   = 'Kill Bill core team'
  s.email    = 'killbilling-users@googlegroups.com'
  s.homepage = 'http://killbill.io'

  s.files         = Dir['lib/**/*']
  s.bindir        = 'bin'
  s.require_paths = ['lib']

  s.rdoc_options << '--exclude' << '.'

  s.add_dependency 'killbill', '~> 8.0'

  s.add_dependency 'sinatra', '~> 1.3.4'
  s.add_dependency 'thread_safe', '~> 0.3.4'
  s.add_dependency 'activerecord', '~> 4.1.0'
  if defined?(JRUBY_VERSION)
    s.add_dependency 'activerecord-bogacs', '~> 0.3'
    s.add_dependency 'activerecord-jdbc-adapter', '~> 1.3', '< 1.5'
    s.add_dependency 'jruby-openssl', '~> 0.9.7'
  end
  s.add_dependency 'actionpack', '~> 4.1.0'
  s.add_dependency 'actionview', '~> 4.1.0'
  # 1.56.0 and above requires Ruby 2.0
  s.add_dependency 'activemerchant', '~> 1.55.0'
  s.add_dependency 'offsite_payments', '~> 2.1.0'
  s.add_dependency 'monetize', '~> 1.1.0'
  s.add_dependency 'money', '~> 6.5.1'

  s.add_development_dependency 'jbundler', '~> 0.9.2'
  s.add_development_dependency 'rake', '>= 10.0.0', '< 11.0.0'
  s.add_development_dependency 'rspec', '~> 2.12.0'
  if defined?(JRUBY_VERSION)
    s.add_development_dependency 'jdbc-sqlite3', '~> 3.7'
    s.add_development_dependency 'jdbc-mariadb', '~> 1.1'
    s.add_development_dependency 'jdbc-postgres', '~> 9.4'
  else
    s.add_development_dependency 'sqlite3', '~> 1.3.7'
  end
end
