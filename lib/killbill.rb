begin
  require 'java'
rescue LoadError => e
  warn 'You need JRuby to run Killbill plugins'
  raise e
end

begin
  java_import 'com.ning.billing.account.api.AccountUserApi'
rescue NameError
  # killbill-api should be provided by the JRuby OSGI bundle. We default to using JBundler for development purposes only
  begin
    require 'jbundler'
  rescue LoadError => e
    warn 'Unable to load killbill-api and couldn\'t find JBundler. For development purposes, make sure to run: bundle install && jbundle install'
    raise e
  end
  java_import 'com.ning.billing.account.api.AccountUserApi'
  warn 'Using JBundler to load killbill-api. This should only happen in development mode!'
  warn "Classpath (see .jbundler/classpath.rb):\n\t#{JBUNDLER_CLASSPATH.join("\n\t")}"
end

require 'killbill/notification'
require 'killbill/payment'
