require 'spec_helper'

module Killbill #:nodoc:
  module Test #:nodoc:
    class TestResponse < ::Killbill::Plugin::ActiveMerchant::ActiveRecord::Response

      self.table_name = 'test_responses'

    end
  end
end

describe Killbill::Plugin::ActiveMerchant::ActiveRecord::Response do

  before :all do
    ::Killbill::Test::TestResponse.delete_all
  end

  it 'should generate the right SQL query' do
    # Check count query (search query numeric)
    expected_query = "SELECT COUNT(DISTINCT \"test_responses\".\"id\") FROM \"test_responses\"  WHERE ((((\"test_responses\".\"kb_payment_id\" = '1234' OR \"test_responses\".\"kb_payment_transaction_id\" = '1234') OR \"test_responses\".\"message\" = '1234') OR \"test_responses\".\"authorization\" = '1234') OR \"test_responses\".\"fraud_review\" = '1234') AND \"test_responses\".\"api_call\" = 'charge' AND \"test_responses\".\"success\" = 't' AND \"test_responses\".\"kb_tenant_id\" = '11-22-33'  ORDER BY \"test_responses\".\"id\""
    # Note that Kill Bill will pass a String, even for numeric types
    ::Killbill::Test::TestResponse.search_query('charge', '1234', '11-22-33').to_sql.should == expected_query

    # Check query with results (search query numeric)
    expected_query = "SELECT  DISTINCT \"test_responses\".* FROM \"test_responses\"  WHERE ((((\"test_responses\".\"kb_payment_id\" = '1234' OR \"test_responses\".\"kb_payment_transaction_id\" = '1234') OR \"test_responses\".\"message\" = '1234') OR \"test_responses\".\"authorization\" = '1234') OR \"test_responses\".\"fraud_review\" = '1234') AND \"test_responses\".\"api_call\" = 'charge' AND \"test_responses\".\"success\" = 't' AND \"test_responses\".\"kb_tenant_id\" = '11-22-33'  ORDER BY \"test_responses\".\"id\" LIMIT 10 OFFSET 0"
    # Note that Kill Bill will pass a String, even for numeric types
    ::Killbill::Test::TestResponse.search_query('charge', '1234', '11-22-33', 0, 10).to_sql.should == expected_query

    # Check count query (search query string)
    expected_query = "SELECT COUNT(DISTINCT \"test_responses\".\"id\") FROM \"test_responses\"  WHERE ((((\"test_responses\".\"kb_payment_id\" = 'XXX' OR \"test_responses\".\"kb_payment_transaction_id\" = 'XXX') OR \"test_responses\".\"message\" = 'XXX') OR \"test_responses\".\"authorization\" = 'XXX') OR \"test_responses\".\"fraud_review\" = 'XXX') AND \"test_responses\".\"api_call\" = 'charge' AND \"test_responses\".\"success\" = 't' AND \"test_responses\".\"kb_tenant_id\" = '11-22-33'  ORDER BY \"test_responses\".\"id\""
    ::Killbill::Test::TestResponse.search_query('charge', 'XXX', '11-22-33').to_sql.should == expected_query

    # Check query with results (search query string)
    expected_query = "SELECT  DISTINCT \"test_responses\".* FROM \"test_responses\"  WHERE ((((\"test_responses\".\"kb_payment_id\" = 'XXX' OR \"test_responses\".\"kb_payment_transaction_id\" = 'XXX') OR \"test_responses\".\"message\" = 'XXX') OR \"test_responses\".\"authorization\" = 'XXX') OR \"test_responses\".\"fraud_review\" = 'XXX') AND \"test_responses\".\"api_call\" = 'charge' AND \"test_responses\".\"success\" = 't' AND \"test_responses\".\"kb_tenant_id\" = '11-22-33'  ORDER BY \"test_responses\".\"id\" LIMIT 10 OFFSET 0"
    ::Killbill::Test::TestResponse.search_query('charge', 'XXX', '11-22-33', 0, 10).to_sql.should == expected_query
  end

  it 'should search all fields' do
    do_search('foo').size.should == 0

    pm       = ::Killbill::Test::TestResponse.create :api_call      => 'charge',
                                                     :kb_account_id => '55-66-77-88',
                                                     :kb_payment_id => '11-22-33-44',
                                                     :kb_tenant_id  => '11-22-33',
                                                     :success       => true

    # Wrong api_call
    ignored1 = ::Killbill::Test::TestResponse.create :api_call      => 'add_payment_method',
                                                     :kb_account_id => '55-66-77-88',
                                                     :kb_payment_id => pm.kb_payment_id,
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
