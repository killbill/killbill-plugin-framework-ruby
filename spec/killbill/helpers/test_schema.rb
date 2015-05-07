require 'active_record'

ActiveRecord::Schema.define(:version => 20140410153635) do
  create_table "test_payment_methods", :force => true do |t|
    t.string   "kb_payment_method_id"      # NULL before Kill Bill knows about it
    t.string   "token"
    t.string   "cc_first_name"
    t.string   "cc_last_name"
    t.string   "cc_type"
    t.string   "cc_exp_month"
    t.string   "cc_exp_year"
    t.string   "cc_number"
    t.string   "cc_last_4"
    t.string   "cc_start_month"
    t.string   "cc_start_year"
    t.string   "cc_issue_number"
    t.string   "cc_verification_value"
    t.string   "cc_track_data"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "country"
    t.boolean  "is_deleted",             :null => false, :default => false
    t.datetime "created_at",             :null => false, :limit => 3
    t.datetime "updated_at",             :null => false, :limit => 3
    t.string   "kb_account_id",          :null => false
    t.string   "kb_tenant_id",           :null => false
  end

  add_index(:test_payment_methods, :kb_account_id)
  add_index(:test_payment_methods, :kb_payment_method_id)

  create_table "test_transactions", :force => true do |t|
    t.integer  "test_response_id",          :null => false
    t.string   "api_call",                  :null => false
    t.string   "kb_payment_id",             :null => false
    t.string   "kb_payment_transaction_id", :null => false
    t.string   "transaction_type",          :null => false
    t.string   "payment_processor_account_id"
    t.string   "txn_id"
    t.integer  "amount_in_cents"
    t.string   "currency"
    t.datetime "created_at",                :null => false, :limit => 3
    t.datetime "updated_at",                :null => false, :limit => 3
    t.string   "kb_account_id",             :null => false
    t.string   "kb_tenant_id",              :null => false
  end

  add_index(:test_transactions, :kb_payment_id)

  create_table "test_responses", :force => true do |t|
    t.string   "api_call",          :null => false
    t.string   "kb_payment_id"
    t.string   "kb_payment_transaction_id"
    t.string   "transaction_type"
    t.string   "payment_processor_account_id"
    t.string   "message"
    t.string   "authorization"
    t.boolean  "fraud_review"
    t.boolean  "test"
    t.string   "avs_result_code"
    t.string   "avs_result_message"
    t.string   "avs_result_street_match"
    t.string   "avs_result_postal_match"
    t.string   "cvv_result_code"
    t.string   "cvv_result_message"
    t.boolean  "success"
    t.datetime "created_at",        :null => false, :limit => 3
    t.datetime "updated_at",        :null => false, :limit => 3
    t.string   "kb_account_id",     :null => false
    t.string   "kb_tenant_id",      :null => false
  end
end
