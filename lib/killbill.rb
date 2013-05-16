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
  end


  #
  # The Killbill Java APIs imported into that jruby bridge
  #
=begin
  IMPORT_KILLBILL_APIS = %w(
    com.ning.billing.account.api.AccountUserApi
    com.ning.billing.analytics.api.sanity.AnalyticsSanityApi
    com.ning.billing.analytics.api.user.AnalyticsUserApi
    com.ning.billing.catalog.api.CatalogUserApi
    com.ning.billing.entitlement.api.migration.EntitlementMigrationApi
    com.ning.billing.entitlement.api.timeline.EntitlementTimelineApi
    com.ning.billing.entitlement.api.transfer.EntitlementTransferApi
    com.ning.billing.entitlement.api.user.EntitlementUserApi
    com.ning.billing.invoice.api.InvoiceMigrationApi
    com.ning.billing.invoice.api.InvoicePaymentApi
    com.ning.billing.invoice.api.InvoiceUserApi
    com.ning.billing.overdue.OverdueUserApi
    com.ning.billing.payment.api.PaymentApi
    com.ning.billing.tenant.api.TenantUserApi
    com.ning.billing.usage.api.UsageUserApi
    com.ning.billing.util.api.AuditUserApi
    com.ning.billing.util.api.CustomFieldUserApi
    com.ning.billing.util.api.ExportUserApi
    com.ning.billing.util.api.TagUserApi
    javax.servlet.http.HttpServlet
  )
=end


  IMPORT_KILLBILL_APIS = %w(
    com.ning.billing.account.api.AccountUserApi
    com.ning.billing.catalog.api.CatalogUserApi
    com.ning.billing.entitlement.api.user.EntitlementUserApi
    com.ning.billing.invoice.api.InvoicePaymentApi
    com.ning.billing.invoice.api.InvoiceUserApi
    com.ning.billing.overdue.OverdueUserApi
    com.ning.billing.payment.api.PaymentApi
    com.ning.billing.util.api.CustomFieldUserApi
    com.ning.billing.util.api.TagUserApi
    javax.servlet.http.HttpServlet
  )

  #
  # The Killbill ruby APIs exported for all the ruby plugins
  #
  EXPORT_KILLBILL_API = %w(
    createAccount
    updateAccount
    getAccountById
    getBundleFromId
    getSubscriptionFromId
    getBundlesForAccount
    getSubscriptionsForBundle
    getBaseSubscription
    createBundleForAccount
    createSubscription
    getNextBillingDate
    getAllInvoicesByAccount
    getInvoice
    getInvoicePayments
    getInvoicePaymentForAttempt
    getRemainingAmountPaid
    getChargebacksByAccountId
    getAccountIdFromInvoicePaymentId
    getChargebacksByPaymentId
    getChargebackById
    getInvoicesByAccount
    getAccountBalance
    getAccountCBA
    getInvoice
    getUnpaidInvoicesByAccountId
    getOverdueStateFor
    getAccountRefunds
    getPaymentRefunds
    getInvoicePayments
    getAccountPayments
    getPayment
    getPaymentMethods
    getPaymentMethodById
    addCustomFields
    getCustomFieldsForAccount
    getTagDefinitions
    createTagDefinition
    deleteTagDefinition
    getTagDefinition
    getTagDefinitions
    addTags
    addTag
    removeTags
    removeTag
    getTagsForAccount
  ).collect { |e| e.snake_case }

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
  require 'killbill/jpayment'
  require 'killbill/jnotification'
rescue LoadError => e
  warn "You need JRuby to run Killbill plugins #{e}"
end

require 'killbill/gen/require_gen'
require 'killbill/notification'
require 'killbill/payment'
