###################################################################################
#                                                                                 #
#                   Copyright 2010-2013 Ning, Inc.                                #
#                                                                                 #
#      Ning licenses this file to you under the Apache License, version 2.0       #
#      (the "License"); you may not use this file except in compliance with the   #
#      License.  You may obtain a copy of the License at:                         #
#                                                                                 #
#          http://www.apache.org/licenses/LICENSE-2.0                             #
#                                                                                 #
#      Unless required by applicable law or agreed to in writing, software        #
#      distributed under the License is distributed on an "AS IS" BASIS, WITHOUT  #
#      WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the  #
#      License for the specific language governing permissions and limitations    #
#      under the License.                                                         #
#                                                                                 #
###################################################################################


#
#                       DO NOT EDIT!!!
#    File automatically generated by killbill-java-parser (git@github.com:killbill/killbill-java-parser.git)
#


module Killbill
  module Plugin
    module Model

      java_package 'org.killbill.billing.payment.api'
      class DirectPayment

        include org.killbill.billing.payment.api.DirectPayment

        attr_accessor :id, :created_date, :updated_date, :account_id, :payment_method_id, :payment_number, :external_key, :auth_amount, :captured_amount, :purchased_amount, :credited_amount, :refunded_amount, :is_auth_voided, :currency, :transactions

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

          # conversion for account_id [type = java.util.UUID]
          @account_id = java.util.UUID.fromString(@account_id.to_s) unless @account_id.nil?

          # conversion for payment_method_id [type = java.util.UUID]
          @payment_method_id = java.util.UUID.fromString(@payment_method_id.to_s) unless @payment_method_id.nil?

          # conversion for payment_number [type = java.lang.Integer]
          @payment_number = @payment_number

          # conversion for external_key [type = java.lang.String]
          @external_key = @external_key.to_s unless @external_key.nil?

          # conversion for auth_amount [type = java.math.BigDecimal]
          if @auth_amount.nil?
            @auth_amount = java.math.BigDecimal::ZERO
          else
            @auth_amount = java.math.BigDecimal.new(@auth_amount.to_s)
          end

          # conversion for captured_amount [type = java.math.BigDecimal]
          if @captured_amount.nil?
            @captured_amount = java.math.BigDecimal::ZERO
          else
            @captured_amount = java.math.BigDecimal.new(@captured_amount.to_s)
          end

          # conversion for purchased_amount [type = java.math.BigDecimal]
          if @purchased_amount.nil?
            @purchased_amount = java.math.BigDecimal::ZERO
          else
            @purchased_amount = java.math.BigDecimal.new(@purchased_amount.to_s)
          end

          # conversion for credited_amount [type = java.math.BigDecimal]
          if @credited_amount.nil?
            @credited_amount = java.math.BigDecimal::ZERO
          else
            @credited_amount = java.math.BigDecimal.new(@credited_amount.to_s)
          end

          # conversion for refunded_amount [type = java.math.BigDecimal]
          if @refunded_amount.nil?
            @refunded_amount = java.math.BigDecimal::ZERO
          else
            @refunded_amount = java.math.BigDecimal.new(@refunded_amount.to_s)
          end

          # conversion for is_auth_voided [type = boolean]
          @is_auth_voided = @is_auth_voided.nil? ? java.lang.Boolean.new(false) : java.lang.Boolean.new(@is_auth_voided)

          # conversion for currency [type = org.killbill.billing.catalog.api.Currency]
          @currency = Java::org.killbill.billing.catalog.api.Currency.value_of("#{@currency.to_s}") unless @currency.nil?

          # conversion for transactions [type = java.util.List]
          tmp = java.util.ArrayList.new
          (@transactions || []).each do |m|
            # conversion for m [type = org.killbill.billing.payment.api.DirectPaymentTransaction]
            m = m.to_java unless m.nil?
            tmp.add(m)
          end
          @transactions = tmp
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

          # conversion for account_id [type = java.util.UUID]
          @account_id = j_obj.account_id
          @account_id = @account_id.nil? ? nil : @account_id.to_s

          # conversion for payment_method_id [type = java.util.UUID]
          @payment_method_id = j_obj.payment_method_id
          @payment_method_id = @payment_method_id.nil? ? nil : @payment_method_id.to_s

          # conversion for payment_number [type = java.lang.Integer]
          @payment_number = j_obj.payment_number

          # conversion for external_key [type = java.lang.String]
          @external_key = j_obj.external_key

          # conversion for auth_amount [type = java.math.BigDecimal]
          @auth_amount = j_obj.auth_amount
          @auth_amount = @auth_amount.nil? ? 0 : BigDecimal.new(@auth_amount.to_s)

          # conversion for captured_amount [type = java.math.BigDecimal]
          @captured_amount = j_obj.captured_amount
          @captured_amount = @captured_amount.nil? ? 0 : BigDecimal.new(@captured_amount.to_s)

          # conversion for purchased_amount [type = java.math.BigDecimal]
          @purchased_amount = j_obj.purchased_amount
          @purchased_amount = @purchased_amount.nil? ? 0 : BigDecimal.new(@purchased_amount.to_s)

          # conversion for credited_amount [type = java.math.BigDecimal]
          @credited_amount = j_obj.credited_amount
          @credited_amount = @credited_amount.nil? ? 0 : BigDecimal.new(@credited_amount.to_s)

          # conversion for refunded_amount [type = java.math.BigDecimal]
          @refunded_amount = j_obj.refunded_amount
          @refunded_amount = @refunded_amount.nil? ? 0 : BigDecimal.new(@refunded_amount.to_s)

          # conversion for is_auth_voided [type = boolean]
          @is_auth_voided = j_obj.is_auth_voided
          if @is_auth_voided.nil?
            @is_auth_voided = false
          else
            tmp_bool = (@is_auth_voided.java_kind_of? java.lang.Boolean) ? @is_auth_voided.boolean_value : @is_auth_voided
            @is_auth_voided = tmp_bool ? true : false
          end

          # conversion for currency [type = org.killbill.billing.catalog.api.Currency]
          @currency = j_obj.currency
          @currency = @currency.to_s.to_sym unless @currency.nil?

          # conversion for transactions [type = java.util.List]
          @transactions = j_obj.transactions
          tmp = []
          (@transactions || []).each do |m|
            # conversion for m [type = org.killbill.billing.payment.api.DirectPaymentTransaction]
            m = Killbill::Plugin::Model::DirectPaymentTransaction.new.to_ruby(m) unless m.nil?
            tmp << m
          end
          @transactions = tmp
          self
        end

      end
    end
  end
end
