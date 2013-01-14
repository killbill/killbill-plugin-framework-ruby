begin
  require 'java'
rescue LoadError => e
  warn 'You need JRuby to run Killbill plugins'
  raise e
end

KILLBILL_APIS = %w(
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
  com.ning.billing.meter.api.MeterUserApi
  com.ning.billing.overdue.OverdueUserApi
  com.ning.billing.payment.api.PaymentApi
  com.ning.billing.tenant.api.TenantUserApi
  com.ning.billing.usage.api.UsageUserApi
  com.ning.billing.util.api.AuditUserApi
  com.ning.billing.util.api.CustomFieldUserApi
  com.ning.billing.util.api.ExportUserApi
  com.ning.billing.util.api.TagUserApi
)

begin
  KILLBILL_APIS.each { |api| java_import api }
rescue NameError
  # killbill-api should be provided by the JRuby OSGI bundle. We default to using JBundler for development purposes only
  begin
    require 'jbundler'
  rescue LoadError => e
    warn 'Unable to load killbill-api and couldn\'t find JBundler. For development purposes, make sure to run: bundle install && jbundle install'
    raise e
  end
  KILLBILL_APIS.each { |api| java_import api }
  warn 'Using JBundler to load killbill-api. This should only happen in development mode!'
  warn "Classpath (see .jbundler/classpath.rb):\n\t#{JBUNDLER_CLASSPATH.join("\n\t")}"
end

require 'killbill/notification'
require 'killbill/payment'
