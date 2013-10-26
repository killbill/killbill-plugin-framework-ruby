begin
  require 'java'

  # Add method snake_case to String as early as possible so all classes below can use it
  class String
     def snake_case
       return downcase if match(/\A[A-Z]+\z/)
       gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
       gsub(/([a-z])([A-Z])/, '\1_\2').
       downcase
     end

     def to_class
       self.split('::').inject(Kernel) do |mod, class_name|
         mod.const_get(class_name)
       end
     end
  end


  #
  # The Killbill Java APIs imported into that jruby bridge
  #
  IMPORT_KILLBILL_APIS = %w(
    com.ning.billing.account.api.AccountUserApi
    com.ning.billing.catalog.api.CatalogUserApi
    com.ning.billing.invoice.api.InvoicePaymentApi
    com.ning.billing.entitlement.api.EntitlementApi
    com.ning.billing.entitlement.api.SubscriptionApi
    com.ning.billing.invoice.api.InvoiceUserApi
    com.ning.billing.overdue.OverdueUserApi
    com.ning.billing.payment.api.PaymentApi
    com.ning.billing.util.api.CustomFieldUserApi
    com.ning.billing.util.api.TagUserApi
    javax.servlet.http.HttpServlet
  )

  begin
    IMPORT_KILLBILL_APIS.each { |api| java_import api }
  rescue NameError
    # killbill-api should be provided by the JRuby OSGI bundle. We default to using JBundler for development purposes only
    begin
      require 'jbundler'
      IMPORT_KILLBILL_APIS.each { |api| java_import api }
      warn 'Using JBundler to load killbill-api (see .jbundler/classpath.rb). This should only happen in development mode!'
    rescue LoadError => e
      warn 'Unable to load killbill-api. For development purposes, use JBundler (create the following Jarfile: http://git.io/eobYXA and run: `bundle install && jbundle install\')'
    end
  end
  # jbundler needs to be loaded first!
  require 'killbill/jplugin'
rescue LoadError => e
  warn "You need JRuby to run Killbill plugins #{e}"
end

require 'tzinfo'
require 'bigdecimal'
require 'killbill/gen/api/require_gen'
require 'killbill/gen/plugin-api/require_gen'
require 'killbill/notification'
require 'killbill/payment'
require 'killbill/currency'
