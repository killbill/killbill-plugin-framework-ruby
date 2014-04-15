require 'spec_helper'

describe Killbill::Plugin::ActiveMerchant::ActiveRecord::Response do

  before :all do
    Killbill::Plugin::ActiveMerchant::ActiveRecord::Response.delete_all
  end

  it 'should generate the right SQL query' do
    # Check count query (search query numeric)
    expected_query = "SELECT COUNT(DISTINCT \"responses\".\"id\") FROM \"responses\"  WHERE (((\"responses\".\"kb_payment_id\" = '1234' OR \"responses\".\"message\" = '1234') OR \"responses\".\"authorization\" = '1234') OR \"responses\".\"fraud_review\" = '1234') AND \"responses\".\"api_call\" = 'charge' AND \"responses\".\"success\" = 't' ORDER BY \"responses\".\"id\""
    # Note that Kill Bill will pass a String, even for numeric types
    Killbill::Plugin::ActiveMerchant::ActiveRecord::Response.search_query('charge', '1234').to_sql.should == expected_query

    # Check query with results (search query numeric)
    expected_query = "SELECT  DISTINCT \"responses\".* FROM \"responses\"  WHERE (((\"responses\".\"kb_payment_id\" = '1234' OR \"responses\".\"message\" = '1234') OR \"responses\".\"authorization\" = '1234') OR \"responses\".\"fraud_review\" = '1234') AND \"responses\".\"api_call\" = 'charge' AND \"responses\".\"success\" = 't' ORDER BY \"responses\".\"id\" LIMIT 10 OFFSET 0"
    # Note that Kill Bill will pass a String, even for numeric types
    Killbill::Plugin::ActiveMerchant::ActiveRecord::Response.search_query('charge', '1234', 0, 10).to_sql.should == expected_query

    # Check count query (search query string)
    expected_query = "SELECT COUNT(DISTINCT \"responses\".\"id\") FROM \"responses\"  WHERE (((\"responses\".\"kb_payment_id\" = 'XXX' OR \"responses\".\"message\" = 'XXX') OR \"responses\".\"authorization\" = 'XXX') OR \"responses\".\"fraud_review\" = 'XXX') AND \"responses\".\"api_call\" = 'charge' AND \"responses\".\"success\" = 't' ORDER BY \"responses\".\"id\""
    Killbill::Plugin::ActiveMerchant::ActiveRecord::Response.search_query('charge', 'XXX').to_sql.should == expected_query

    # Check query with results (search query string)
    expected_query = "SELECT  DISTINCT \"responses\".* FROM \"responses\"  WHERE (((\"responses\".\"kb_payment_id\" = 'XXX' OR \"responses\".\"message\" = 'XXX') OR \"responses\".\"authorization\" = 'XXX') OR \"responses\".\"fraud_review\" = 'XXX') AND \"responses\".\"api_call\" = 'charge' AND \"responses\".\"success\" = 't' ORDER BY \"responses\".\"id\" LIMIT 10 OFFSET 0"
    Killbill::Plugin::ActiveMerchant::ActiveRecord::Response.search_query('charge', 'XXX', 0, 10).to_sql.should == expected_query
  end

  it 'should search all fields' do
    do_search('foo').size.should == 0

    pm = Killbill::Plugin::ActiveMerchant::ActiveRecord::Response.create :api_call => 'charge',
                                                                         :kb_payment_id => '11-22-33-44',
                                                                         :success => true

    # Wrong api_call
    ignored1 = Killbill::Plugin::ActiveMerchant::ActiveRecord::Response.create :api_call => 'add_payment_method',
                                                                               :kb_payment_id => pm.kb_payment_id,
                                                                               :success => true

    # Not successful
    ignored2 = Killbill::Plugin::ActiveMerchant::ActiveRecord::Response.create :api_call => 'charge',
                                                                               :kb_payment_id => pm.kb_payment_id,
                                                                               :success => false

    do_search(pm.kb_payment_id).size.should == 1

    pm2 = Killbill::Plugin::ActiveMerchant::ActiveRecord::Response.create :api_call => 'charge',
                                                                          :kb_payment_id => pm.kb_payment_id,
                                                                          :success => true

    do_search(pm.kb_payment_id).size.should == 2
  end

  private

  def do_search(search_key)
    pagination = Killbill::Plugin::ActiveMerchant::ActiveRecord::Response.search(search_key)
    pagination.current_offset.should == 0
    results = pagination.iterator.to_a
    pagination.total_nb_records.should == results.size
    results
  end
end
