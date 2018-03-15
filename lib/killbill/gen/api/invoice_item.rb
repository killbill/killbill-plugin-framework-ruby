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
    module Model

      java_package 'org.killbill.billing.invoice.api'
      class InvoiceItem

        include org.killbill.billing.invoice.api.InvoiceItem

        attr_accessor :id, :created_date, :updated_date, :invoice_item_type, :invoice_id, :account_id, :child_account_id, :start_date, :end_date, :amount, :currency, :description, :bundle_id, :subscription_id, :plan_name, :pretty_plan_name, :phase_name, :pretty_phase_name, :usage_name, :pretty_usage_name, :rate, :linked_item_id, :quantity, :item_details

        def initialize()
        end

        def to_java()
          # conversion for id [type = java.util.UUID]
          @id = java.util.UUID.fromString(@id.to_s) unless @id.nil?

          # conversion for created_date [type = org.joda.time.DateTime]
          if !@created_date.nil?
            @created_date =  (@created_date.kind_of? Time) ? DateTime.parse(@created_date.to_s) : @created_date
            @created_date = Java::org.joda.time.DateTime.new(@created_date.to_s, Java::org.joda.time.DateTimeZone::UTC)
          end

          # conversion for updated_date [type = org.joda.time.DateTime]
          if !@updated_date.nil?
            @updated_date =  (@updated_date.kind_of? Time) ? DateTime.parse(@updated_date.to_s) : @updated_date
            @updated_date = Java::org.joda.time.DateTime.new(@updated_date.to_s, Java::org.joda.time.DateTimeZone::UTC)
          end

          # conversion for invoice_item_type [type = org.killbill.billing.invoice.api.InvoiceItemType]
          @invoice_item_type = Java::org.killbill.billing.invoice.api.InvoiceItemType.value_of( @invoice_item_type.to_s ) unless @invoice_item_type.nil?

          # conversion for invoice_id [type = java.util.UUID]
          @invoice_id = java.util.UUID.fromString(@invoice_id.to_s) unless @invoice_id.nil?

          # conversion for account_id [type = java.util.UUID]
          @account_id = java.util.UUID.fromString(@account_id.to_s) unless @account_id.nil?

          # conversion for child_account_id [type = java.util.UUID]
          @child_account_id = java.util.UUID.fromString(@child_account_id.to_s) unless @child_account_id.nil?

          # conversion for start_date [type = org.joda.time.LocalDate]
          if !@start_date.nil?
            @start_date = Java::org.joda.time.LocalDate.parse(@start_date.to_s)
          end

          # conversion for end_date [type = org.joda.time.LocalDate]
          if !@end_date.nil?
            @end_date = Java::org.joda.time.LocalDate.parse(@end_date.to_s)
          end

          # conversion for amount [type = java.math.BigDecimal]
          if @amount.nil?
            @amount = java.math.BigDecimal::ZERO
          else
            @amount = java.math.BigDecimal.new(@amount.to_s)
          end

          # conversion for currency [type = org.killbill.billing.catalog.api.Currency]
          @currency = Java::org.killbill.billing.catalog.api.Currency.value_of( @currency.to_s ) unless @currency.nil?

          # conversion for description [type = java.lang.String]
          @description = @description.to_s unless @description.nil?

          # conversion for bundle_id [type = java.util.UUID]
          @bundle_id = java.util.UUID.fromString(@bundle_id.to_s) unless @bundle_id.nil?

          # conversion for subscription_id [type = java.util.UUID]
          @subscription_id = java.util.UUID.fromString(@subscription_id.to_s) unless @subscription_id.nil?

          # conversion for plan_name [type = java.lang.String]
          @plan_name = @plan_name.to_s unless @plan_name.nil?

          # conversion for pretty_plan_name [type = java.lang.String]
          @pretty_plan_name = @pretty_plan_name.to_s unless @pretty_plan_name.nil?

          # conversion for phase_name [type = java.lang.String]
          @phase_name = @phase_name.to_s unless @phase_name.nil?

          # conversion for pretty_phase_name [type = java.lang.String]
          @pretty_phase_name = @pretty_phase_name.to_s unless @pretty_phase_name.nil?

          # conversion for usage_name [type = java.lang.String]
          @usage_name = @usage_name.to_s unless @usage_name.nil?

          # conversion for pretty_usage_name [type = java.lang.String]
          @pretty_usage_name = @pretty_usage_name.to_s unless @pretty_usage_name.nil?

          # conversion for rate [type = java.math.BigDecimal]
          if @rate.nil?
            @rate = java.math.BigDecimal::ZERO
          else
            @rate = java.math.BigDecimal.new(@rate.to_s)
          end

          # conversion for linked_item_id [type = java.util.UUID]
          @linked_item_id = java.util.UUID.fromString(@linked_item_id.to_s) unless @linked_item_id.nil?

          # conversion for quantity [type = java.lang.Integer]
          @quantity = @quantity

          # conversion for item_details [type = java.lang.String]
          @item_details = @item_details.to_s unless @item_details.nil?
          self
        end

        def to_ruby(j_obj)
          # conversion for id [type = java.util.UUID]
          @id = j_obj.id
          @id = @id.nil? ? nil : @id.to_s

          # conversion for created_date [type = org.joda.time.DateTime]
          @created_date = j_obj.created_date
          if !@created_date.nil?
            fmt = Java::org.joda.time.format.ISODateTimeFormat.date_time_no_millis # See https://github.com/killbill/killbill-java-parser/issues/3
            str = fmt.print(@created_date)
            @created_date = DateTime.iso8601(str)
          end

          # conversion for updated_date [type = org.joda.time.DateTime]
          @updated_date = j_obj.updated_date
          if !@updated_date.nil?
            fmt = Java::org.joda.time.format.ISODateTimeFormat.date_time_no_millis # See https://github.com/killbill/killbill-java-parser/issues/3
            str = fmt.print(@updated_date)
            @updated_date = DateTime.iso8601(str)
          end

          # conversion for invoice_item_type [type = org.killbill.billing.invoice.api.InvoiceItemType]
          @invoice_item_type = j_obj.invoice_item_type
          @invoice_item_type = @invoice_item_type.to_s.to_sym unless @invoice_item_type.nil?

          # conversion for invoice_id [type = java.util.UUID]
          @invoice_id = j_obj.invoice_id
          @invoice_id = @invoice_id.nil? ? nil : @invoice_id.to_s

          # conversion for account_id [type = java.util.UUID]
          @account_id = j_obj.account_id
          @account_id = @account_id.nil? ? nil : @account_id.to_s

          # conversion for child_account_id [type = java.util.UUID]
          @child_account_id = j_obj.child_account_id
          @child_account_id = @child_account_id.nil? ? nil : @child_account_id.to_s

          # conversion for start_date [type = org.joda.time.LocalDate]
          @start_date = j_obj.start_date
          if !@start_date.nil?
            @start_date = @start_date.to_s
          end

          # conversion for end_date [type = org.joda.time.LocalDate]
          @end_date = j_obj.end_date
          if !@end_date.nil?
            @end_date = @end_date.to_s
          end

          # conversion for amount [type = java.math.BigDecimal]
          @amount = j_obj.amount
          @amount = @amount.nil? ? 0 : BigDecimal.new(@amount.to_s)

          # conversion for currency [type = org.killbill.billing.catalog.api.Currency]
          @currency = j_obj.currency
          @currency = @currency.to_s.to_sym unless @currency.nil?

          # conversion for description [type = java.lang.String]
          @description = j_obj.description

          # conversion for bundle_id [type = java.util.UUID]
          @bundle_id = j_obj.bundle_id
          @bundle_id = @bundle_id.nil? ? nil : @bundle_id.to_s

          # conversion for subscription_id [type = java.util.UUID]
          @subscription_id = j_obj.subscription_id
          @subscription_id = @subscription_id.nil? ? nil : @subscription_id.to_s

          # conversion for plan_name [type = java.lang.String]
          @plan_name = j_obj.plan_name

          # conversion for pretty_plan_name [type = java.lang.String]
          @pretty_plan_name = j_obj.pretty_plan_name

          # conversion for phase_name [type = java.lang.String]
          @phase_name = j_obj.phase_name

          # conversion for pretty_phase_name [type = java.lang.String]
          @pretty_phase_name = j_obj.pretty_phase_name

          # conversion for usage_name [type = java.lang.String]
          @usage_name = j_obj.usage_name

          # conversion for pretty_usage_name [type = java.lang.String]
          @pretty_usage_name = j_obj.pretty_usage_name

          # conversion for rate [type = java.math.BigDecimal]
          @rate = j_obj.rate
          @rate = @rate.nil? ? 0 : BigDecimal.new(@rate.to_s)

          # conversion for linked_item_id [type = java.util.UUID]
          @linked_item_id = j_obj.linked_item_id
          @linked_item_id = @linked_item_id.nil? ? nil : @linked_item_id.to_s

          # conversion for quantity [type = java.lang.Integer]
          @quantity = j_obj.quantity

          # conversion for item_details [type = java.lang.String]
          @item_details = j_obj.item_details
          self
        end

      end
    end
  end
end
