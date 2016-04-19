CREATE TABLE <%= identifier %>_payment_methods (
  id serial UNIQUE,
  kb_payment_method_id varchar(255) DEFAULT NULL,
  token varchar(255) DEFAULT NULL,
  cc_first_name varchar(255) DEFAULT NULL,
  cc_last_name varchar(255) DEFAULT NULL,
  cc_type varchar(255) DEFAULT NULL,
  cc_exp_month varchar(255) DEFAULT NULL,
  cc_exp_year varchar(255) DEFAULT NULL,
  cc_number varchar(255) DEFAULT NULL,
  cc_last_4 varchar(255) DEFAULT NULL,
  cc_start_month varchar(255) DEFAULT NULL,
  cc_start_year varchar(255) DEFAULT NULL,
  cc_issue_number varchar(255) DEFAULT NULL,
  cc_verification_value varchar(255) DEFAULT NULL,
  cc_track_data varchar(255) DEFAULT NULL,
  address1 varchar(255) DEFAULT NULL,
  address2 varchar(255) DEFAULT NULL,
  city varchar(255) DEFAULT NULL,
  state varchar(255) DEFAULT NULL,
  zip varchar(255) DEFAULT NULL,
  country varchar(255) DEFAULT NULL,
  is_deleted boolean NOT NULL DEFAULT '0',
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  kb_account_id varchar(255) DEFAULT NULL,
  kb_tenant_id varchar(255) DEFAULT NULL,
  PRIMARY KEY (id)
) /*! ENGINE=InnoDB CHARACTER SET utf8 COLLATE utf8_bin */;
CREATE INDEX index_<%= identifier %>_payment_methods_kb_account_id ON <%= identifier %>_payment_methods(kb_account_id);
CREATE INDEX index_<%= identifier %>_payment_methods_kb_payment_method_id ON <%= identifier %>_payment_methods(kb_payment_method_id);

CREATE TABLE <%= identifier %>_transactions (
  id serial UNIQUE,
  <%= identifier %>_response_id bigint /*! unsigned */ NOT NULL,
  api_call varchar(255) NOT NULL,
  kb_payment_id varchar(255) NOT NULL,
  kb_payment_transaction_id varchar(255) NOT NULL,
  transaction_type varchar(255) NOT NULL,
  payment_processor_account_id varchar(255) DEFAULT NULL,
  txn_id varchar(255) DEFAULT NULL,
  amount_in_cents int DEFAULT NULL,
  currency varchar(255) DEFAULT NULL,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  kb_account_id varchar(255) NOT NULL,
  kb_tenant_id varchar(255) NOT NULL,
  PRIMARY KEY (id)
) /*! ENGINE=InnoDB CHARACTER SET utf8 COLLATE utf8_bin */;
CREATE INDEX index_<%= identifier %>_transactions_kb_payment_id ON <%= identifier %>_transactions(kb_payment_id);
CREATE INDEX index_<%= identifier %>_transactions_<%= identifier %>_response_id ON <%= identifier %>_transactions(<%= identifier %>_response_id);

CREATE TABLE <%= identifier %>_responses (
  id serial UNIQUE,
  api_call varchar(255) NOT NULL,
  kb_payment_id varchar(255) DEFAULT NULL,
  kb_payment_transaction_id varchar(255) DEFAULT NULL,
  transaction_type varchar(255) DEFAULT NULL,
  payment_processor_account_id varchar(255) DEFAULT NULL,
  message text DEFAULT NULL,
  authorisation varchar(255) DEFAULT NULL,
  fraud_review boolean DEFAULT NULL,
  test boolean DEFAULT NULL,
  avs_result_code varchar(255) DEFAULT NULL,
  avs_result_message varchar(255) DEFAULT NULL,
  avs_result_street_match varchar(255) DEFAULT NULL,
  avs_result_postal_match varchar(255) DEFAULT NULL,
  cvv_result_code varchar(255) DEFAULT NULL,
  cvv_result_message varchar(255) DEFAULT NULL,
  success boolean DEFAULT NULL,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  kb_account_id varchar(255) DEFAULT NULL,
  kb_tenant_id varchar(255) DEFAULT NULL,
  PRIMARY KEY (id)
) /*! ENGINE=InnoDB CHARACTER SET utf8 COLLATE utf8_bin */;
CREATE INDEX index_<%= identifier %>_responses_kb_payment_id_kb_tenant_id ON <%= identifier %>_responses(kb_payment_id, kb_tenant_id);
