require 'spec_helper'
require 'spec/killbill/helpers/transaction_spec'

module Killbill #:nodoc:
  module Test #:nodoc:
    class TestResponse < ::Killbill::Plugin::ActiveMerchant::ActiveRecord::Response

      self.table_name = 'test_responses'

      has_one :test_transaction

    end
  end
end

describe Killbill::Plugin::ActiveMerchant::ActiveRecord::Response do

  before :all do
    ::Killbill::Test::TestResponse.delete_all
  end

  it 'should construct responses correctly' do
    api_call                     = 'for debugging only'
    kb_account_id                = SecureRandom.uuid
    kb_payment_id                = SecureRandom.uuid
    kb_payment_transaction_id    = SecureRandom.uuid
    transaction_type             = :PURCHASE
    payment_processor_account_id = 'petit_poucet'
    kb_tenant_id                 = SecureRandom.uuid
    response                     = ::ActiveMerchant::Billing::Response.new(true, 'Message', {}, {
        :authorization => SecureRandom.uuid,
        :avs_result    => ::ActiveMerchant::Billing::AVSResult.new(:code => 'P')
    })

    r = ::Killbill::Test::TestResponse.from_response(api_call, kb_account_id, kb_payment_id, kb_payment_transaction_id, transaction_type, payment_processor_account_id, kb_tenant_id, response, {}, ::Killbill::Test::TestResponse)
    r.api_call.should == api_call
    r.kb_account_id.should == kb_account_id
    r.kb_payment_id.should == kb_payment_id
    r.kb_payment_transaction_id.should == kb_payment_transaction_id
    r.transaction_type.should == transaction_type
    r.payment_processor_account_id.should == payment_processor_account_id
    r.kb_tenant_id.should == kb_tenant_id
    r.message.should == response.message
    r.authorization.should == response.authorization
    r.fraud_review.should == response.fraud_review?
    r.test.should == response.test
    r.avs_result_code.should == 'P'
    r.avs_result_message.should == 'Postal code matches, but street address not verified.'
    r.avs_result_street_match.should be_nil
    r.avs_result_postal_match.should == 'Y'
    r.cvv_result_code.should be_nil
    r.cvv_result_message.should be_nil
    r.success.should == response.success?

    # Verify conversion to PaymentTransactionInfoPlugin
    ptip = r.to_transaction_info_plugin
    ptip.kb_payment_id.should == kb_payment_id
    ptip.kb_transaction_payment_id.should == kb_payment_transaction_id
    ptip.transaction_type.should == transaction_type
    # No associated transaction
    ptip.amount.should be_nil
    ptip.currency.should be_nil
    ptip.status.should == :PROCESSED
    ptip.gateway_error.should == 'Message'
    ptip.gateway_error_code.should be_nil
    ptip.first_payment_reference_id.should be_nil
    ptip.second_payment_reference_id.should be_nil
    ptip.properties.size.should == 12
  end

  it 'should create responses and transactions correctly' do
    api_call                     = 'for debugging only'
    kb_account_id                = SecureRandom.uuid
    kb_payment_id                = SecureRandom.uuid
    kb_payment_transaction_id    = SecureRandom.uuid
    transaction_type             = :PURCHASE
    payment_processor_account_id = 'petit_poucet'
    kb_tenant_id                 = SecureRandom.uuid
    success_response             = ::ActiveMerchant::Billing::Response.new(true, 'Message', {}, {
        :authorization => SecureRandom.uuid,
        :avs_result    => ::ActiveMerchant::Billing::AVSResult.new(:code => 'P')
    })
    failure_response             = ::ActiveMerchant::Billing::Response.new(false, 'Message', {}, {
        :authorization => SecureRandom.uuid,
        :avs_result    => ::ActiveMerchant::Billing::AVSResult.new(:code => 'P')
    })

    response, transaction = ::Killbill::Test::TestResponse.create_response_and_transaction('test', ::Killbill::Test::TestTransaction, api_call, kb_account_id, kb_payment_id, kb_payment_transaction_id, transaction_type, payment_processor_account_id, kb_tenant_id, success_response, 120, 'USD', {}, ::Killbill::Test::TestResponse)
    found_response        = ::Killbill::Test::TestResponse.find(response.id)
    found_response.should == response
    found_response.test_transaction.should == transaction
    found_transaction = ::Killbill::Test::TestTransaction.find(transaction.id)
    found_transaction.should == transaction
    found_transaction.test_response.should == response

    response, transaction = ::Killbill::Test::TestResponse.create_response_and_transaction('test', ::Killbill::Test::TestTransaction, api_call, kb_account_id, kb_payment_id, kb_payment_transaction_id, transaction_type, payment_processor_account_id, kb_tenant_id, failure_response, 120, 'USD', {}, ::Killbill::Test::TestResponse)
    transaction.should be_nil
    found_response = ::Killbill::Test::TestResponse.find(response.id)
    found_response.should == response
    found_response.test_transaction.should be_nil

    # Lookup responses for kb_payment_id
    responses = ::Killbill::Test::TestResponse.responses_from_kb_payment_id(transaction_type, kb_payment_id, kb_tenant_id)
    responses.size.should == 2
    responses[0].success.should be_true
    responses[1].success.should be_false

    # Lookup responses for kb_payment_transaction_id
    responses = ::Killbill::Test::TestResponse.responses_from_kb_payment_transaction_id(transaction_type, kb_payment_transaction_id, kb_tenant_id)
    responses.size.should == 2
    responses[0].success.should be_true
    responses[1].success.should be_false

    # Dummy queries
    ::Killbill::Test::TestResponse.responses_from_kb_payment_id(:foo, kb_payment_id, kb_tenant_id).size.should == 0
    ::Killbill::Test::TestResponse.responses_from_kb_payment_id(transaction_type, SecureRandom.uuid, kb_tenant_id).size.should == 0
    ::Killbill::Test::TestResponse.responses_from_kb_payment_id(transaction_type, kb_payment_id, SecureRandom.uuid).size.should == 0
    ::Killbill::Test::TestResponse.responses_from_kb_payment_transaction_id(:foo, kb_payment_transaction_id, kb_tenant_id).size.should == 0
    ::Killbill::Test::TestResponse.responses_from_kb_payment_transaction_id(transaction_type, SecureRandom.uuid, kb_tenant_id).size.should == 0
    ::Killbill::Test::TestResponse.responses_from_kb_payment_transaction_id(transaction_type, kb_payment_transaction_id, SecureRandom.uuid).size.should == 0
  end

  it 'should generate the right SQL query' do
    # Check count query (search query numeric)
    expected_query = "SELECT COUNT(DISTINCT \"test_responses\".\"id\") FROM \"test_responses\"  WHERE ((((\"test_responses\".\"kb_payment_id\" = '1234' OR \"test_responses\".\"kb_payment_transaction_id\" = '1234') OR \"test_responses\".\"message\" = '1234') OR \"test_responses\".\"authorization\" = '1234') OR \"test_responses\".\"fraud_review\" = '1234') AND \"test_responses\".\"success\" = 't' AND \"test_responses\".\"kb_tenant_id\" = '11-22-33'  ORDER BY \"test_responses\".\"id\""
    # Note that Kill Bill will pass a String, even for numeric types
    ::Killbill::Test::TestResponse.search_query('1234', '11-22-33').to_sql.should == expected_query

    # Check query with results (search query numeric)
    expected_query = "SELECT  DISTINCT \"test_responses\".* FROM \"test_responses\"  WHERE ((((\"test_responses\".\"kb_payment_id\" = '1234' OR \"test_responses\".\"kb_payment_transaction_id\" = '1234') OR \"test_responses\".\"message\" = '1234') OR \"test_responses\".\"authorization\" = '1234') OR \"test_responses\".\"fraud_review\" = '1234') AND \"test_responses\".\"success\" = 't' AND \"test_responses\".\"kb_tenant_id\" = '11-22-33'  ORDER BY \"test_responses\".\"id\" LIMIT 10 OFFSET 0"
    # Note that Kill Bill will pass a String, even for numeric types
    ::Killbill::Test::TestResponse.search_query('1234', '11-22-33', 0, 10).to_sql.should == expected_query

    # Check count query (search query string)
    expected_query = "SELECT COUNT(DISTINCT \"test_responses\".\"id\") FROM \"test_responses\"  WHERE ((((\"test_responses\".\"kb_payment_id\" = 'XXX' OR \"test_responses\".\"kb_payment_transaction_id\" = 'XXX') OR \"test_responses\".\"message\" = 'XXX') OR \"test_responses\".\"authorization\" = 'XXX') OR \"test_responses\".\"fraud_review\" = 'XXX') AND \"test_responses\".\"success\" = 't' AND \"test_responses\".\"kb_tenant_id\" = '11-22-33'  ORDER BY \"test_responses\".\"id\""
    ::Killbill::Test::TestResponse.search_query('XXX', '11-22-33').to_sql.should == expected_query

    # Check query with results (search query string)
    expected_query = "SELECT  DISTINCT \"test_responses\".* FROM \"test_responses\"  WHERE ((((\"test_responses\".\"kb_payment_id\" = 'XXX' OR \"test_responses\".\"kb_payment_transaction_id\" = 'XXX') OR \"test_responses\".\"message\" = 'XXX') OR \"test_responses\".\"authorization\" = 'XXX') OR \"test_responses\".\"fraud_review\" = 'XXX') AND \"test_responses\".\"success\" = 't' AND \"test_responses\".\"kb_tenant_id\" = '11-22-33'  ORDER BY \"test_responses\".\"id\" LIMIT 10 OFFSET 0"
    ::Killbill::Test::TestResponse.search_query('XXX', '11-22-33', 0, 10).to_sql.should == expected_query
  end

  it 'should search all fields' do
    do_search('foo').size.should == 0

    pm       = ::Killbill::Test::TestResponse.create :api_call      => 'charge',
                                                     :kb_account_id => '55-66-77-88',
                                                     :kb_payment_id => '11-22-33-44',
                                                     :kb_tenant_id  => '11-22-33',
                                                     :success       => true

    # Not successful
    ignored2 = ::Killbill::Test::TestResponse.create :api_call      => 'charge',
                                                     :kb_account_id => '55-66-77-88',
                                                     :kb_payment_id => pm.kb_payment_id,
                                                     :kb_tenant_id  => '11-22-33',
                                                     :success       => false

    do_search(pm.kb_payment_id).size.should == 1

    pm2 = ::Killbill::Test::TestResponse.create :api_call      => 'charge',
                                                :kb_account_id => '55-66-77-88',
                                                :kb_payment_id => pm.kb_payment_id,
                                                :kb_tenant_id  => '11-22-33',
                                                :success       => true

    do_search(pm.kb_payment_id).size.should == 2
  end

  private

  def do_search(search_key)
    pagination = ::Killbill::Test::TestResponse.search(search_key, '11-22-33')
    pagination.current_offset.should == 0
    results = pagination.iterator.to_a
    pagination.total_nb_records.should == results.size
    results
  end
end
