#############################################################################################
#                                                                                           #
#                   Copyright 2010-2013 Ning, Inc.                                          #
#                   Copyright 2014 Groupon, Inc.                                            #
#                   Copyright 2014 The Billing Project, LLC                                 #
#                                                                                           #
#      The Billing Project licenses this file to you under the Apache License, version 2.0  #
#      (the "License"); you may not use this file except in compliance with the             #
#      License.  You may obtain a copy of the License at:                                   #
#                                                                                           #
#          http://www.apache.org/licenses/LICENSE-2.0                                       #
#                                                                                           #
#      Unless required by applicable law or agreed to in writing, software                  #
#      distributed under the License is distributed on an "AS IS" BASIS, WITHOUT            #
#      WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the            #
#      License for the specific language governing permissions and limitations              #
#      under the License.                                                                   #
#                                                                                           #
#############################################################################################


#
#                       DO NOT EDIT!!!
#    File automatically generated by killbill-java-parser (git@github.com:killbill/killbill-java-parser.git)
#


module Killbill
  module Plugin
    module Api

      java_package 'org.killbill.billing.entitlement.api'
      class EntitlementApi

        include org.killbill.billing.entitlement.api.EntitlementApi

        def initialize(real_java_api)
          @real_java_api = real_java_api
        end


        java_signature 'Java::java.util.UUID createBaseEntitlement(Java::java.util.UUID, Java::org.killbill.billing.entitlement.api.EntitlementSpecifier, Java::java.lang.String, Java::org.joda.time.LocalDate, Java::org.joda.time.LocalDate, Java::boolean, Java::boolean, Java::java.lang.Iterable, Java::org.killbill.billing.util.callcontext.CallContext)'
        def create_base_entitlement(accountId, spec, externalKey, entitlementEffectiveDate, billingEffectiveDate, isMigrated, renameCancelledBundleIfExist, properties, context)

          # conversion for accountId [type = java.util.UUID]
          accountId = java.util.UUID.fromString(accountId.to_s) unless accountId.nil?

          # conversion for spec [type = org.killbill.billing.entitlement.api.EntitlementSpecifier]
          spec = spec.to_java unless spec.nil?

          # conversion for externalKey [type = java.lang.String]
          externalKey = externalKey.to_s unless externalKey.nil?

          # conversion for entitlementEffectiveDate [type = org.joda.time.LocalDate]
          if !entitlementEffectiveDate.nil?
            entitlementEffectiveDate = Java::org.joda.time.LocalDate.parse(entitlementEffectiveDate.to_s)
          end

          # conversion for billingEffectiveDate [type = org.joda.time.LocalDate]
          if !billingEffectiveDate.nil?
            billingEffectiveDate = Java::org.joda.time.LocalDate.parse(billingEffectiveDate.to_s)
          end

          # conversion for isMigrated [type = boolean]
          isMigrated = isMigrated.nil? ? java.lang.Boolean.new(false) : java.lang.Boolean.new(isMigrated)

          # conversion for renameCancelledBundleIfExist [type = boolean]
          renameCancelledBundleIfExist = renameCancelledBundleIfExist.nil? ? java.lang.Boolean.new(false) : java.lang.Boolean.new(renameCancelledBundleIfExist)

          # conversion for properties [type = java.lang.Iterable]
          tmp = java.util.ArrayList.new
          (properties || []).each do |m|
            # conversion for m [type = org.killbill.billing.payment.api.PluginProperty]
            m = m.to_java unless m.nil?
            tmp.add(m)
          end
          properties = tmp

          # conversion for context [type = org.killbill.billing.util.callcontext.CallContext]
          context = context.to_java unless context.nil?
          begin
            res = @real_java_api.create_base_entitlement(accountId, spec, externalKey, entitlementEffectiveDate, billingEffectiveDate, isMigrated, renameCancelledBundleIfExist, properties, context)
            # conversion for res [type = java.util.UUID]
            res = res.nil? ? nil : res.to_s
            return res
          rescue Java::org.killbill.billing.entitlement.api.EntitlementApiException => e
            raise Killbill::Plugin::Model::EntitlementApiException.new.to_ruby(e)
          end
        end

        java_signature 'Java::java.util.List createBaseEntitlementsWithAddOns(Java::java.util.UUID, Java::java.lang.Iterable, Java::boolean, Java::java.lang.Iterable, Java::org.killbill.billing.util.callcontext.CallContext)'
        def create_base_entitlements_with_add_ons(accountId, baseEntitlementWithAddOnsSpecifier, renameCancelledBundleIfExist, properties, context)

          # conversion for accountId [type = java.util.UUID]
          accountId = java.util.UUID.fromString(accountId.to_s) unless accountId.nil?

          # conversion for baseEntitlementWithAddOnsSpecifier [type = java.lang.Iterable]
          tmp = java.util.ArrayList.new
          (baseEntitlementWithAddOnsSpecifier || []).each do |m|
            # conversion for m [type = org.killbill.billing.entitlement.api.BaseEntitlementWithAddOnsSpecifier]
            m = m.to_java unless m.nil?
            tmp.add(m)
          end
          baseEntitlementWithAddOnsSpecifier = tmp

          # conversion for renameCancelledBundleIfExist [type = boolean]
          renameCancelledBundleIfExist = renameCancelledBundleIfExist.nil? ? java.lang.Boolean.new(false) : java.lang.Boolean.new(renameCancelledBundleIfExist)

          # conversion for properties [type = java.lang.Iterable]
          tmp = java.util.ArrayList.new
          (properties || []).each do |m|
            # conversion for m [type = org.killbill.billing.payment.api.PluginProperty]
            m = m.to_java unless m.nil?
            tmp.add(m)
          end
          properties = tmp

          # conversion for context [type = org.killbill.billing.util.callcontext.CallContext]
          context = context.to_java unless context.nil?
          begin
            res = @real_java_api.create_base_entitlements_with_add_ons(accountId, baseEntitlementWithAddOnsSpecifier, renameCancelledBundleIfExist, properties, context)
            # conversion for res [type = java.util.List]
            tmp = []
            (res || []).each do |m|
              # conversion for m [type = java.util.UUID]
              m = m.nil? ? nil : m.to_s
              tmp << m
            end
            res = tmp
            return res
          rescue Java::org.killbill.billing.entitlement.api.EntitlementApiException => e
            raise Killbill::Plugin::Model::EntitlementApiException.new.to_ruby(e)
          end
        end

        java_signature 'Java::java.util.UUID addEntitlement(Java::java.util.UUID, Java::org.killbill.billing.entitlement.api.EntitlementSpecifier, Java::org.joda.time.LocalDate, Java::org.joda.time.LocalDate, Java::boolean, Java::java.lang.Iterable, Java::org.killbill.billing.util.callcontext.CallContext)'
        def add_entitlement(bundleId, spec, entitlementEffectiveDate, billingEffectiveDate, isMigrated, properties, context)

          # conversion for bundleId [type = java.util.UUID]
          bundleId = java.util.UUID.fromString(bundleId.to_s) unless bundleId.nil?

          # conversion for spec [type = org.killbill.billing.entitlement.api.EntitlementSpecifier]
          spec = spec.to_java unless spec.nil?

          # conversion for entitlementEffectiveDate [type = org.joda.time.LocalDate]
          if !entitlementEffectiveDate.nil?
            entitlementEffectiveDate = Java::org.joda.time.LocalDate.parse(entitlementEffectiveDate.to_s)
          end

          # conversion for billingEffectiveDate [type = org.joda.time.LocalDate]
          if !billingEffectiveDate.nil?
            billingEffectiveDate = Java::org.joda.time.LocalDate.parse(billingEffectiveDate.to_s)
          end

          # conversion for isMigrated [type = boolean]
          isMigrated = isMigrated.nil? ? java.lang.Boolean.new(false) : java.lang.Boolean.new(isMigrated)

          # conversion for properties [type = java.lang.Iterable]
          tmp = java.util.ArrayList.new
          (properties || []).each do |m|
            # conversion for m [type = org.killbill.billing.payment.api.PluginProperty]
            m = m.to_java unless m.nil?
            tmp.add(m)
          end
          properties = tmp

          # conversion for context [type = org.killbill.billing.util.callcontext.CallContext]
          context = context.to_java unless context.nil?
          begin
            res = @real_java_api.add_entitlement(bundleId, spec, entitlementEffectiveDate, billingEffectiveDate, isMigrated, properties, context)
            # conversion for res [type = java.util.UUID]
            res = res.nil? ? nil : res.to_s
            return res
          rescue Java::org.killbill.billing.entitlement.api.EntitlementApiException => e
            raise Killbill::Plugin::Model::EntitlementApiException.new.to_ruby(e)
          end
        end

        java_signature 'Java::java.util.List getDryRunStatusForChange(Java::java.util.UUID, Java::java.lang.String, Java::org.joda.time.LocalDate, Java::org.killbill.billing.util.callcontext.TenantContext)'
        def get_dry_run_status_for_change(bundleId, targetProductName, effectiveDate, context)

          # conversion for bundleId [type = java.util.UUID]
          bundleId = java.util.UUID.fromString(bundleId.to_s) unless bundleId.nil?

          # conversion for targetProductName [type = java.lang.String]
          targetProductName = targetProductName.to_s unless targetProductName.nil?

          # conversion for effectiveDate [type = org.joda.time.LocalDate]
          if !effectiveDate.nil?
            effectiveDate = Java::org.joda.time.LocalDate.parse(effectiveDate.to_s)
          end

          # conversion for context [type = org.killbill.billing.util.callcontext.TenantContext]
          context = context.to_java unless context.nil?
          begin
            res = @real_java_api.get_dry_run_status_for_change(bundleId, targetProductName, effectiveDate, context)
            # conversion for res [type = java.util.List]
            tmp = []
            (res || []).each do |m|
              # conversion for m [type = org.killbill.billing.entitlement.api.EntitlementAOStatusDryRun]
              m = Killbill::Plugin::Model::EntitlementAOStatusDryRun.new.to_ruby(m) unless m.nil?
              tmp << m
            end
            res = tmp
            return res
          rescue Java::org.killbill.billing.entitlement.api.EntitlementApiException => e
            raise Killbill::Plugin::Model::EntitlementApiException.new.to_ruby(e)
          end
        end

        java_signature 'Java::void pause(Java::java.util.UUID, Java::org.joda.time.LocalDate, Java::java.lang.Iterable, Java::org.killbill.billing.util.callcontext.CallContext)'
        def pause(bundleId, effectiveDate, properties, context)

          # conversion for bundleId [type = java.util.UUID]
          bundleId = java.util.UUID.fromString(bundleId.to_s) unless bundleId.nil?

          # conversion for effectiveDate [type = org.joda.time.LocalDate]
          if !effectiveDate.nil?
            effectiveDate = Java::org.joda.time.LocalDate.parse(effectiveDate.to_s)
          end

          # conversion for properties [type = java.lang.Iterable]
          tmp = java.util.ArrayList.new
          (properties || []).each do |m|
            # conversion for m [type = org.killbill.billing.payment.api.PluginProperty]
            m = m.to_java unless m.nil?
            tmp.add(m)
          end
          properties = tmp

          # conversion for context [type = org.killbill.billing.util.callcontext.CallContext]
          context = context.to_java unless context.nil?
          @real_java_api.pause(bundleId, effectiveDate, properties, context)
        end

        java_signature 'Java::void resume(Java::java.util.UUID, Java::org.joda.time.LocalDate, Java::java.lang.Iterable, Java::org.killbill.billing.util.callcontext.CallContext)'
        def resume(bundleId, effectiveDate, properties, context)

          # conversion for bundleId [type = java.util.UUID]
          bundleId = java.util.UUID.fromString(bundleId.to_s) unless bundleId.nil?

          # conversion for effectiveDate [type = org.joda.time.LocalDate]
          if !effectiveDate.nil?
            effectiveDate = Java::org.joda.time.LocalDate.parse(effectiveDate.to_s)
          end

          # conversion for properties [type = java.lang.Iterable]
          tmp = java.util.ArrayList.new
          (properties || []).each do |m|
            # conversion for m [type = org.killbill.billing.payment.api.PluginProperty]
            m = m.to_java unless m.nil?
            tmp.add(m)
          end
          properties = tmp

          # conversion for context [type = org.killbill.billing.util.callcontext.CallContext]
          context = context.to_java unless context.nil?
          @real_java_api.resume(bundleId, effectiveDate, properties, context)
        end

        java_signature 'Java::org.killbill.billing.entitlement.api.Entitlement getEntitlementForId(Java::java.util.UUID, Java::org.killbill.billing.util.callcontext.TenantContext)'
        def get_entitlement_for_id(id, context)

          # conversion for id [type = java.util.UUID]
          id = java.util.UUID.fromString(id.to_s) unless id.nil?

          # conversion for context [type = org.killbill.billing.util.callcontext.TenantContext]
          context = context.to_java unless context.nil?
          begin
            res = @real_java_api.get_entitlement_for_id(id, context)
            # conversion for res [type = org.killbill.billing.entitlement.api.Entitlement]
            res = Killbill::Plugin::Model::Entitlement.new.to_ruby(res) unless res.nil?
            return res
          rescue Java::org.killbill.billing.entitlement.api.EntitlementApiException => e
            raise Killbill::Plugin::Model::EntitlementApiException.new.to_ruby(e)
          end
        end

        java_signature 'Java::java.util.List getAllEntitlementsForBundle(Java::java.util.UUID, Java::org.killbill.billing.util.callcontext.TenantContext)'
        def get_all_entitlements_for_bundle(bundleId, context)

          # conversion for bundleId [type = java.util.UUID]
          bundleId = java.util.UUID.fromString(bundleId.to_s) unless bundleId.nil?

          # conversion for context [type = org.killbill.billing.util.callcontext.TenantContext]
          context = context.to_java unless context.nil?
          begin
            res = @real_java_api.get_all_entitlements_for_bundle(bundleId, context)
            # conversion for res [type = java.util.List]
            tmp = []
            (res || []).each do |m|
              # conversion for m [type = org.killbill.billing.entitlement.api.Entitlement]
              m = Killbill::Plugin::Model::Entitlement.new.to_ruby(m) unless m.nil?
              tmp << m
            end
            res = tmp
            return res
          rescue Java::org.killbill.billing.entitlement.api.EntitlementApiException => e
            raise Killbill::Plugin::Model::EntitlementApiException.new.to_ruby(e)
          end
        end

        java_signature 'Java::java.util.List getAllEntitlementsForAccountIdAndExternalKey(Java::java.util.UUID, Java::java.lang.String, Java::org.killbill.billing.util.callcontext.TenantContext)'
        def get_all_entitlements_for_account_id_and_external_key(accountId, externalKey, context)

          # conversion for accountId [type = java.util.UUID]
          accountId = java.util.UUID.fromString(accountId.to_s) unless accountId.nil?

          # conversion for externalKey [type = java.lang.String]
          externalKey = externalKey.to_s unless externalKey.nil?

          # conversion for context [type = org.killbill.billing.util.callcontext.TenantContext]
          context = context.to_java unless context.nil?
          begin
            res = @real_java_api.get_all_entitlements_for_account_id_and_external_key(accountId, externalKey, context)
            # conversion for res [type = java.util.List]
            tmp = []
            (res || []).each do |m|
              # conversion for m [type = org.killbill.billing.entitlement.api.Entitlement]
              m = Killbill::Plugin::Model::Entitlement.new.to_ruby(m) unless m.nil?
              tmp << m
            end
            res = tmp
            return res
          rescue Java::org.killbill.billing.entitlement.api.EntitlementApiException => e
            raise Killbill::Plugin::Model::EntitlementApiException.new.to_ruby(e)
          end
        end

        java_signature 'Java::java.util.List getAllEntitlementsForAccountId(Java::java.util.UUID, Java::org.killbill.billing.util.callcontext.TenantContext)'
        def get_all_entitlements_for_account_id(accountId, context)

          # conversion for accountId [type = java.util.UUID]
          accountId = java.util.UUID.fromString(accountId.to_s) unless accountId.nil?

          # conversion for context [type = org.killbill.billing.util.callcontext.TenantContext]
          context = context.to_java unless context.nil?
          begin
            res = @real_java_api.get_all_entitlements_for_account_id(accountId, context)
            # conversion for res [type = java.util.List]
            tmp = []
            (res || []).each do |m|
              # conversion for m [type = org.killbill.billing.entitlement.api.Entitlement]
              m = Killbill::Plugin::Model::Entitlement.new.to_ruby(m) unless m.nil?
              tmp << m
            end
            res = tmp
            return res
          rescue Java::org.killbill.billing.entitlement.api.EntitlementApiException => e
            raise Killbill::Plugin::Model::EntitlementApiException.new.to_ruby(e)
          end
        end

        java_signature 'Java::java.util.UUID transferEntitlements(Java::java.util.UUID, Java::java.util.UUID, Java::java.lang.String, Java::org.joda.time.LocalDate, Java::java.lang.Iterable, Java::org.killbill.billing.util.callcontext.CallContext)'
        def transfer_entitlements(sourceAccountId, destAccountId, externalKey, effectiveDate, properties, context)

          # conversion for sourceAccountId [type = java.util.UUID]
          sourceAccountId = java.util.UUID.fromString(sourceAccountId.to_s) unless sourceAccountId.nil?

          # conversion for destAccountId [type = java.util.UUID]
          destAccountId = java.util.UUID.fromString(destAccountId.to_s) unless destAccountId.nil?

          # conversion for externalKey [type = java.lang.String]
          externalKey = externalKey.to_s unless externalKey.nil?

          # conversion for effectiveDate [type = org.joda.time.LocalDate]
          if !effectiveDate.nil?
            effectiveDate = Java::org.joda.time.LocalDate.parse(effectiveDate.to_s)
          end

          # conversion for properties [type = java.lang.Iterable]
          tmp = java.util.ArrayList.new
          (properties || []).each do |m|
            # conversion for m [type = org.killbill.billing.payment.api.PluginProperty]
            m = m.to_java unless m.nil?
            tmp.add(m)
          end
          properties = tmp

          # conversion for context [type = org.killbill.billing.util.callcontext.CallContext]
          context = context.to_java unless context.nil?
          begin
            res = @real_java_api.transfer_entitlements(sourceAccountId, destAccountId, externalKey, effectiveDate, properties, context)
            # conversion for res [type = java.util.UUID]
            res = res.nil? ? nil : res.to_s
            return res
          rescue Java::org.killbill.billing.entitlement.api.EntitlementApiException => e
            raise Killbill::Plugin::Model::EntitlementApiException.new.to_ruby(e)
          end
        end

        java_signature 'Java::java.util.UUID transferEntitlementsOverrideBillingPolicy(Java::java.util.UUID, Java::java.util.UUID, Java::java.lang.String, Java::org.joda.time.LocalDate, Java::org.killbill.billing.catalog.api.BillingActionPolicy, Java::java.lang.Iterable, Java::org.killbill.billing.util.callcontext.CallContext)'
        def transfer_entitlements_override_billing_policy(sourceAccountId, destAccountId, externalKey, effectiveDate, billingPolicy, properties, context)

          # conversion for sourceAccountId [type = java.util.UUID]
          sourceAccountId = java.util.UUID.fromString(sourceAccountId.to_s) unless sourceAccountId.nil?

          # conversion for destAccountId [type = java.util.UUID]
          destAccountId = java.util.UUID.fromString(destAccountId.to_s) unless destAccountId.nil?

          # conversion for externalKey [type = java.lang.String]
          externalKey = externalKey.to_s unless externalKey.nil?

          # conversion for effectiveDate [type = org.joda.time.LocalDate]
          if !effectiveDate.nil?
            effectiveDate = Java::org.joda.time.LocalDate.parse(effectiveDate.to_s)
          end

          # conversion for billingPolicy [type = org.killbill.billing.catalog.api.BillingActionPolicy]
          billingPolicy = Java::org.killbill.billing.catalog.api.BillingActionPolicy.value_of( billingPolicy.to_s ) unless billingPolicy.nil?

          # conversion for properties [type = java.lang.Iterable]
          tmp = java.util.ArrayList.new
          (properties || []).each do |m|
            # conversion for m [type = org.killbill.billing.payment.api.PluginProperty]
            m = m.to_java unless m.nil?
            tmp.add(m)
          end
          properties = tmp

          # conversion for context [type = org.killbill.billing.util.callcontext.CallContext]
          context = context.to_java unless context.nil?
          begin
            res = @real_java_api.transfer_entitlements_override_billing_policy(sourceAccountId, destAccountId, externalKey, effectiveDate, billingPolicy, properties, context)
            # conversion for res [type = java.util.UUID]
            res = res.nil? ? nil : res.to_s
            return res
          rescue Java::org.killbill.billing.entitlement.api.EntitlementApiException => e
            raise Killbill::Plugin::Model::EntitlementApiException.new.to_ruby(e)
          end
        end
      end
    end
  end
end
