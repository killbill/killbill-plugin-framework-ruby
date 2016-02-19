module Killbill
  module Plugin
    module ActiveMerchant
      module ActiveRecord
        require 'active_record'
        require 'active_merchant'
        require 'time'
        require 'killbill/helpers/active_merchant/active_record/models/helpers'

        class PaymentMethod < ::ActiveRecord::Base

          extend ::Killbill::Plugin::ActiveMerchant::Helpers

          self.abstract_class = true
          # See Response#from_response
          self.record_timestamps = false

          @@quotes_cache = build_quotes_cache

          def self.from_response(kb_account_id, kb_payment_method_id, kb_tenant_id, cc_or_token, response, options, extra_params = {}, model = PaymentMethod)
            # See Response#from_response
            current_time = Time.now.utc
            model.new({
                          :kb_account_id        => kb_account_id,
                          :kb_payment_method_id => kb_payment_method_id,
                          :kb_tenant_id         => kb_tenant_id,
                          :token                => cc_or_token.kind_of?(::ActiveMerchant::Billing::CreditCard) ? response.authorization.presence : (cc_or_token || response.authorization).presence,
                          :cc_first_name        => cc_or_token.kind_of?(::ActiveMerchant::Billing::CreditCard) ? cc_or_token.first_name : extra_params[:cc_first_name],
                          :cc_last_name         => cc_or_token.kind_of?(::ActiveMerchant::Billing::CreditCard) ? cc_or_token.last_name : extra_params[:cc_last_name],
                          :cc_type              => cc_or_token.kind_of?(::ActiveMerchant::Billing::CreditCard) ? cc_or_token.brand : extra_params[:cc_type],
                          :cc_exp_month         => cc_or_token.kind_of?(::ActiveMerchant::Billing::CreditCard) ? cc_or_token.month : extra_params[:cc_exp_month],
                          :cc_exp_year          => cc_or_token.kind_of?(::ActiveMerchant::Billing::CreditCard) ? cc_or_token.year : extra_params[:cc_exp_year],
                          :cc_last_4            => cc_or_token.kind_of?(::ActiveMerchant::Billing::CreditCard) ? cc_or_token.last_digits : extra_params[:cc_last_4],
                          :cc_number            => cc_or_token.kind_of?(::ActiveMerchant::Billing::CreditCard) ? cc_or_token.number : nil,
                          :address1             => (options[:billing_address] || {})[:address1],
                          :address2             => (options[:billing_address] || {})[:address2],
                          :city                 => (options[:billing_address] || {})[:city],
                          :state                => (options[:billing_address] || {})[:state],
                          :zip                  => (options[:billing_address] || {})[:zip],
                          :country              => (options[:billing_address] || {})[:country],
                          :created_at           => current_time,
                          :updated_at           => current_time
                      }.merge!(extra_params.compact)) # Don't override with nil values
          end

          def self.from_kb_account_id(kb_account_id, kb_tenant_id)
            if kb_tenant_id.nil?
              where("kb_account_id = #{@@quotes_cache[kb_account_id]} AND kb_tenant_id is NULL AND is_deleted = #{@@quotes_cache[false]}").order(:id)
            else
              where("kb_account_id = #{@@quotes_cache[kb_account_id]} AND kb_tenant_id = #{@@quotes_cache[kb_tenant_id]} AND is_deleted = #{@@quotes_cache[false]}").order(:id)
            end
          end

          def self.from_kb_account_id_and_token(token, kb_account_id, kb_tenant_id)
            from_kb_account_id(kb_account_id, kb_tenant_id).where("token = #{@@quotes_cache[token]}").order(:id)
          end

          def self.from_kb_payment_method_id(kb_payment_method_id, kb_tenant_id)
            if kb_tenant_id.nil?
              payment_methods = where("kb_payment_method_id = #{@@quotes_cache[kb_payment_method_id]} AND kb_tenant_id is NULL AND is_deleted = #{@@quotes_cache[false]}")
            else
              payment_methods = where("kb_payment_method_id = #{@@quotes_cache[kb_payment_method_id]} AND kb_tenant_id = #{@@quotes_cache[kb_tenant_id]} AND is_deleted = #{@@quotes_cache[false]}")
            end
            raise "No payment method found for payment method #{kb_payment_method_id} and tenant #{kb_tenant_id}" if payment_methods.empty?
            raise "Kill Bill payment method #{kb_payment_method_id} mapping to multiple active plugin payment methods" if payment_methods.size > 1
            payment_methods[0]
          end

          def self.mark_as_deleted!(kb_payment_method_id, kb_tenant_id)
            payment_method = from_kb_payment_method_id(kb_payment_method_id, kb_tenant_id)
            payment_method.is_deleted = true
            payment_method.save!(shared_activerecord_options)
          end

          # Override in your plugin if needed
          def self.search_where_clause(t, search_key)
            where_clause =     t[:kb_account_id].eq(search_key)
                           .or(t[:kb_payment_method_id].eq(search_key))
                           .or(t[:token].eq(search_key))
                           .or(t[:cc_type].eq(search_key))
                           .or(t[:state].eq(search_key))
                           .or(t[:zip].eq(search_key))
                           .or(t[:cc_first_name].matches("%#{search_key}%"))
                           .or(t[:cc_last_name].matches("%#{search_key}%"))
                           .or(t[:address1].matches("%#{search_key}%"))
                           .or(t[:address2].matches("%#{search_key}%"))
                           .or(t[:city].matches("%#{search_key}%"))
                           .or(t[:country].matches("%#{search_key}%"))

            # Coming from Kill Bill, search_key will always be a String. Check to see if it represents a numeric for numeric-only fields
            if search_key.is_a?(Numeric) or search_key.to_s =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/
              where_clause = where_clause.or(t[:cc_exp_month].eq(search_key))
                                         .or(t[:cc_exp_year].eq(search_key))
                                         .or(t[:cc_last_4].eq(search_key))
            end

            where_clause
          end

          # VisibleForTesting
          def self.search_query(search_key, kb_tenant_id, offset = nil, limit = nil)
            t = self.arel_table

            if kb_tenant_id.nil?
              query = t.where(search_where_clause(t, search_key))
            else
              query = t.where(search_where_clause(t, search_key).and(t[:kb_tenant_id].eq(kb_tenant_id)))
            end

            if offset.blank? and limit.blank?
              # true is for count distinct
              query.project(t[:id].count(true))
            else
              query.order(t[:id])
              query.skip(offset) unless offset.blank?
              query.take(limit) unless limit.blank?
              query.project(t[Arel.star])
              # Not chainable
              query.distinct
            end
            query
          end

          def self.search(search_key, kb_tenant_id, offset = 0, limit = 100)
            pagination = Killbill::Plugin::Model::Pagination.new
            pagination.current_offset = offset
            pagination.total_nb_records = self.count_by_sql(self.search_query(search_key, kb_tenant_id))
            pagination.max_nb_records = self.count
            pagination.next_offset = (!pagination.total_nb_records.nil? && offset + limit >= pagination.total_nb_records) ? nil : offset + limit
            # Reduce the limit if the specified value is larger than the number of records
            actual_limit = [pagination.max_nb_records, limit].min
            pagination.iterator = StreamyResultSet.new(actual_limit) do |offset,limit|
              self.find_by_sql(self.search_query(search_key, kb_tenant_id, offset, limit))
                  .map(&:to_payment_method_plugin)
            end
            pagination
          end

          # Override in your plugin if needed
          def external_payment_method_id
            token
          end

          # Override in your plugin if needed
          def is_default
            false
          end

          def to_payment_method_plugin
            properties = []
            properties << create_plugin_property('token', external_payment_method_id)
            properties << create_plugin_property('ccFirstName', cc_first_name)
            properties << create_plugin_property('ccLastName', cc_last_name)
            properties << create_plugin_property('ccName', cc_name)
            properties << create_plugin_property('ccType', cc_type)
            properties << create_plugin_property('ccExpirationMonth', cc_exp_month)
            properties << create_plugin_property('ccExpirationYear', cc_exp_year)
            properties << create_plugin_property('ccLast4', cc_last_4)
            properties << create_plugin_property('ccNumber', cc_number)
            properties << create_plugin_property('address1', address1)
            properties << create_plugin_property('address2', address2)
            properties << create_plugin_property('city', city)
            properties << create_plugin_property('state', state)
            properties << create_plugin_property('zip', zip)
            properties << create_plugin_property('country', country)

            pm_plugin = Killbill::Plugin::Model::PaymentMethodPlugin.new
            pm_plugin.kb_payment_method_id = kb_payment_method_id
            pm_plugin.external_payment_method_id = external_payment_method_id
            pm_plugin.is_default_payment_method = is_default
            pm_plugin.properties = properties

            pm_plugin
          end

          def to_payment_method_info_plugin
            pm_info_plugin = Killbill::Plugin::Model::PaymentMethodInfoPlugin.new
            pm_info_plugin.account_id = kb_account_id
            pm_info_plugin.payment_method_id = kb_payment_method_id
            pm_info_plugin.is_default = is_default
            pm_info_plugin.external_payment_method_id = external_payment_method_id
            pm_info_plugin
          end

          def cc_name
            if cc_first_name and cc_last_name
              "#{cc_first_name} #{cc_last_name}"
            elsif cc_first_name
              cc_first_name
            elsif cc_last_name
              cc_last_name
            else
              nil
            end
          end

          private

          def create_plugin_property(key, value)
            prop = Killbill::Plugin::Model::PluginProperty.new
            prop.key = key
            prop.value = value
            prop
          end
        end
      end
    end
  end
end
