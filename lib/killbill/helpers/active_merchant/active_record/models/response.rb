module Killbill
  module Plugin
    module ActiveMerchant
      module ActiveRecord
        require 'active_record'
        require 'active_merchant'
        require 'money'
        require 'time'
        require 'killbill/helpers/active_merchant/active_record/models/helpers'

        class Response < ::ActiveRecord::Base

          extend ::Killbill::Plugin::ActiveMerchant::Helpers

          self.abstract_class = true
          self.record_timestamps = false

          @@quotes_cache = build_quotes_cache

          def self.from_response(api_call, kb_account_id, kb_payment_id, kb_payment_transaction_id, transaction_type, payment_processor_account_id, kb_tenant_id, response, extra_params = {}, model = Response)
            # Under high load, Rails sometimes fails to set timestamps. Unclear why...
            # But regardless, for performance reasons, we want to set these timestamps ourselves
            # See ActiveRecord::Timestamp
            current_time = Time.now.utc
            remove_sensitive_data_and_compact(extra_params)
            model.new({
                          :api_call                     => api_call,
                          :kb_account_id                => kb_account_id,
                          :kb_payment_id                => kb_payment_id,
                          :kb_payment_transaction_id    => kb_payment_transaction_id,
                          :transaction_type             => transaction_type,
                          :payment_processor_account_id => payment_processor_account_id,
                          :kb_tenant_id                 => kb_tenant_id,
                          :message                      => response.message,
                          :authorization                => response.authorization,
                          :fraud_review                 => response.fraud_review?,
                          :test                         => response.test?,
                          :avs_result_code              => response.avs_result.kind_of?(::ActiveMerchant::Billing::AVSResult) ? response.avs_result.code : response.avs_result['code'],
                          :avs_result_message           => response.avs_result.kind_of?(::ActiveMerchant::Billing::AVSResult) ? response.avs_result.message : response.avs_result['message'],
                          :avs_result_street_match      => response.avs_result.kind_of?(::ActiveMerchant::Billing::AVSResult) ? response.avs_result.street_match : response.avs_result['street_match'],
                          :avs_result_postal_match      => response.avs_result.kind_of?(::ActiveMerchant::Billing::AVSResult) ? response.avs_result.postal_match : response.avs_result['postal_match'],
                          :cvv_result_code              => response.cvv_result.kind_of?(::ActiveMerchant::Billing::CVVResult) ? response.cvv_result.code : response.cvv_result['code'],
                          :cvv_result_message           => response.cvv_result.kind_of?(::ActiveMerchant::Billing::CVVResult) ? response.cvv_result.message : response.cvv_result['message'],
                          :success                      => response.success?,
                          :created_at                   => current_time,
                          :updated_at                   => current_time
                      }.merge!(extra_params))
          end

          def self.create_response_and_transaction(identifier, transaction_model, api_call, kb_account_id, kb_payment_id, kb_payment_transaction_id, transaction_type, payment_processor_account_id, kb_tenant_id, gw_response, amount_in_cents, currency, extra_params = {}, model = Response)
            response, transaction, exception = nil

            # Rails wraps all create/save calls in a transaction. To speed things up, create a single transaction for both rows.
            # This has a small gotcha in the unhappy path though (see below).
            with_connection_and_transaction do
              # Save the response to our logs
              response = from_response(api_call, kb_account_id, kb_payment_id, kb_payment_transaction_id, transaction_type, payment_processor_account_id, kb_tenant_id, gw_response, extra_params, model)
              response.save!(shared_activerecord_options)

              transaction = nil
              txn_id      = response.txn_id
              if response.success and !kb_payment_id.blank?
                # Record the transaction
                # Note that we want to avoid throwing an exception here because we don't want to rollback the response row
                begin
                  # Originally, we used response.send("build_#{identifier}_transaction"), but the ActiveRecord magic was adding
                  # about 20% overhead - instead, we now construct the transaction record manually
                  transaction = transaction_model.new(:kb_account_id                => kb_account_id,
                                                      :kb_tenant_id                 => kb_tenant_id,
                                                      :amount_in_cents              => amount_in_cents,
                                                      :currency                     => currency,
                                                      :api_call                     => api_call,
                                                      :kb_payment_id                => kb_payment_id,
                                                      :kb_payment_transaction_id    => kb_payment_transaction_id,
                                                      :transaction_type             => transaction_type,
                                                      :payment_processor_account_id => payment_processor_account_id,
                                                      :txn_id                       => txn_id,
                                                      "#{identifier}_response_id"   => response.id,
                                                      # See Response#from_response
                                                      :created_at                   => response.created_at,
                                                      :updated_at                   => response.updated_at)
                  transaction.save!(shared_activerecord_options)
                rescue => e
                  exception = e
                end
              end
            end

            raise exception unless exception.nil?

            return response, transaction
          end

          def self.from_kb_payment_id(transaction_model, kb_payment_id, kb_tenant_id)
            association = transaction_model.table_name.singularize.to_sym
            # Use eager_load to force Rails to issue a single query (see https://github.com/killbill/killbill-plugin-framework-ruby/issues/32)
            eager_load(association)
                .where(:kb_payment_id => kb_payment_id, :kb_tenant_id => kb_tenant_id)
                .order(:created_at)
          end

          def to_transaction_info_plugin(transaction=nil)
            error_details = {}

            if transaction.nil?
              amount_in_cents = nil
              currency        = nil
              created_date    = created_at
              # See Killbill::Plugin::ActiveMerchant::Gateway
              error_details   = JSON.parse(message) rescue {}
            else
              amount_in_cents = transaction.amount_in_cents
              currency        = transaction.currency
              created_date    = transaction.created_at
            end

            # See https://github.com/killbill/killbill-plugin-framework-ruby/issues/43
            # Note: status could also be :PENDING, but it would be handled only in the plugins which need it
            if !error_details['payment_plugin_status'].blank?
              status = error_details['payment_plugin_status'].to_sym
            else
              # Note: (success && transaction.nil?) _could_ happen (see above), but it would be an issue on our side
              # (the payment did go through in the gateway).
              status = success ? :PROCESSED : :ERROR
            end

            t_info_plugin                             = Killbill::Plugin::Model::PaymentTransactionInfoPlugin.new
            t_info_plugin.kb_payment_id               = kb_payment_id
            t_info_plugin.kb_transaction_payment_id   = kb_payment_transaction_id
            t_info_plugin.transaction_type            = transaction_type.nil? ? nil : transaction_type.to_sym
            t_info_plugin.amount                      = Money.new(amount_in_cents, currency).to_d if currency
            t_info_plugin.currency                    = currency
            t_info_plugin.created_date                = created_date
            t_info_plugin.effective_date              = effective_date
            t_info_plugin.status                      = status
            t_info_plugin.gateway_error               = error_details['exception_message'] || gateway_error
            t_info_plugin.gateway_error_code          = error_details['exception_class'] || gateway_error_code
            t_info_plugin.first_payment_reference_id  = first_reference_id
            t_info_plugin.second_payment_reference_id = second_reference_id

            properties = []
            properties << create_plugin_property('payment_processor_account_id', payment_processor_account_id)
            properties << create_plugin_property('message', message)
            properties << create_plugin_property('authorization', authorization)
            properties << create_plugin_property('fraudReview', fraud_review)
            properties << create_plugin_property('test', self.read_attribute(:test))
            properties << create_plugin_property('avsResultCode', avs_result_code)
            properties << create_plugin_property('avsResultMessage', avs_result_message)
            properties << create_plugin_property('avsResultStreetMatch', avs_result_street_match)
            properties << create_plugin_property('avsResultPostalMatch', avs_result_postal_match)
            properties << create_plugin_property('cvvResultCode', cvv_result_code)
            properties << create_plugin_property('cvvResultMessage', cvv_result_message)
            properties << create_plugin_property('success', success)
            t_info_plugin.properties = properties

            t_info_plugin
          end

          # Override in your plugin if needed
          def self.search_where_clause(t, search_key)
            # Exact matches only
            where_clause = t[:kb_payment_id].eq(search_key)
                                            .or(t[:kb_payment_transaction_id].eq(search_key))
                                            .or(t[:message].eq(search_key))
                                            .or(t[:authorization].eq(search_key))

            # Only search successful payments and refunds
            where_clause = where_clause.and(t[:success].eq(true))

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
            pagination                  = ::Killbill::Plugin::Model::Pagination.new
            pagination.current_offset   = offset
            pagination.total_nb_records = self.count_by_sql(self.search_query(search_key, kb_tenant_id))
            pagination.max_nb_records   = self.where(:success => true).count
            pagination.next_offset      = (!pagination.total_nb_records.nil? && offset + limit >= pagination.total_nb_records) ? nil : offset + limit
            # Reduce the limit if the specified value is larger than the number of records
            actual_limit                = [pagination.max_nb_records, limit].min
            pagination.iterator         = ::Killbill::Plugin::ActiveMerchant::ActiveRecord::StreamyResultSet.new(actual_limit) do |offset, limit|
              self.find_by_sql(self.search_query(search_key, kb_tenant_id, offset, limit)).map { |x| x.to_transaction_info_plugin }
            end
            pagination
          end

          def self.remove_sensitive_data_and_compact(extra_params)
            extra_params.compact!
            extra_params.delete_if { |k, _| sensitive_fields.include?(k) }
          end

          # Override in your plugin if needed
          def self.sensitive_fields
            []
          end

          # Override in your plugin if needed
          def txn_id
            authorization
          end

          # Override in your plugin if needed
          def first_reference_id
            nil
          end

          # Override in your plugin if needed
          def second_reference_id
            nil
          end

          # Override in your plugin if needed
          def effective_date
            created_at
          end

          # Override in your plugin if needed
          def gateway_error
            message
          end

          # Override in your plugin if needed
          def gateway_error_code
            nil
          end

          # authorization was the old name (reserved on PostgreSQL) - make sure we support both column names for backward compatibility

          def authorization=(auth)
            write_attribute(column_for_attribute('authorization').name, auth)
          end

          def authorization
            read_attribute(column_for_attribute('authorization').name)
          end

          def column_for_attribute(name)
            name == 'authorization' ? (super('authorisation') || super('authorization')) : super(name)
          end

          private

          def create_plugin_property(key, value)
            prop       = Killbill::Plugin::Model::PluginProperty.new
            prop.key   = key
            prop.value = value
            prop
          end

          class << self
            [:kb_payment_id, :kb_payment_transaction_id].each do |attribute|
              define_method("responses_from_#{attribute.to_s}") do |transaction_type, attribute_value, kb_tenant_id, how_many = :multiple|
                if kb_tenant_id.nil?
                  if transaction_type.nil?
                    transactions = where("kb_tenant_id is NULL AND #{attribute.to_s} = ?", attribute_value).order(:created_at)
                  else
                    transactions = where("transaction_type = #{@@quotes_cache[transaction_type]} AND kb_tenant_id is NULL AND #{attribute.to_s} = #{@@quotes_cache[attribute_value]}").order(:created_at)
                  end
                else
                  if transaction_type.nil?
                    transactions = where("kb_tenant_id = #{@@quotes_cache[kb_tenant_id]} AND #{attribute.to_s} = #{@@quotes_cache[attribute_value]}").order(:created_at)
                  else
                    transactions = where("transaction_type = #{@@quotes_cache[transaction_type]} AND kb_tenant_id = #{@@quotes_cache[kb_tenant_id]} AND #{attribute.to_s} = #{@@quotes_cache[attribute_value]}").order(:created_at)
                  end
                end
                if how_many == :single
                  raise "Kill Bill #{attribute} = #{attribute_value} mapping to multiple plugin transactions" if transactions.size > 1
                  transactions[0]
                else
                  transactions
                end
              end
            end
          end
        end
      end
    end
  end
end