require 'spec_helper'

describe Killbill::Plugin::ActiveMerchant::ActiveRecord::PaymentMethod do

  before :all do
    Killbill::Plugin::ActiveMerchant::ActiveRecord::PaymentMethod.delete_all
  end

  it 'should generate the right SQL query' do
    # Check count query (search query numeric)
    expected_query = "SELECT COUNT(DISTINCT \"payment_methods\".\"id\") FROM \"payment_methods\"  WHERE (((((((((((((\"payment_methods\".\"kb_account_id\" = '1234' OR \"payment_methods\".\"kb_payment_method_id\" = '1234') OR \"payment_methods\".\"cc_type\" = '1234') OR \"payment_methods\".\"state\" = '1234') OR \"payment_methods\".\"zip\" = '1234') OR \"payment_methods\".\"cc_first_name\" LIKE '%1234%') OR \"payment_methods\".\"cc_last_name\" LIKE '%1234%') OR \"payment_methods\".\"address1\" LIKE '%1234%') OR \"payment_methods\".\"address2\" LIKE '%1234%') OR \"payment_methods\".\"city\" LIKE '%1234%') OR \"payment_methods\".\"country\" LIKE '%1234%') OR \"payment_methods\".\"cc_exp_month\" = 1234) OR \"payment_methods\".\"cc_exp_year\" = 1234) OR \"payment_methods\".\"cc_last_4\" = 1234) ORDER BY \"payment_methods\".\"id\""
    # Note that Kill Bill will pass a String, even for numeric types
    Killbill::Plugin::ActiveMerchant::ActiveRecord::PaymentMethod.search_query('1234').to_sql.should == expected_query

    # Check query with results (search query numeric)
    expected_query = "SELECT  DISTINCT \"payment_methods\".* FROM \"payment_methods\"  WHERE (((((((((((((\"payment_methods\".\"kb_account_id\" = '1234' OR \"payment_methods\".\"kb_payment_method_id\" = '1234') OR \"payment_methods\".\"cc_type\" = '1234') OR \"payment_methods\".\"state\" = '1234') OR \"payment_methods\".\"zip\" = '1234') OR \"payment_methods\".\"cc_first_name\" LIKE '%1234%') OR \"payment_methods\".\"cc_last_name\" LIKE '%1234%') OR \"payment_methods\".\"address1\" LIKE '%1234%') OR \"payment_methods\".\"address2\" LIKE '%1234%') OR \"payment_methods\".\"city\" LIKE '%1234%') OR \"payment_methods\".\"country\" LIKE '%1234%') OR \"payment_methods\".\"cc_exp_month\" = 1234) OR \"payment_methods\".\"cc_exp_year\" = 1234) OR \"payment_methods\".\"cc_last_4\" = 1234) ORDER BY \"payment_methods\".\"id\" LIMIT 10 OFFSET 0"
    # Note that Kill Bill will pass a String, even for numeric types
    Killbill::Plugin::ActiveMerchant::ActiveRecord::PaymentMethod.search_query('1234', 0, 10).to_sql.should == expected_query

    # Check count query (search query string)
    expected_query = "SELECT COUNT(DISTINCT \"payment_methods\".\"id\") FROM \"payment_methods\"  WHERE ((((((((((\"payment_methods\".\"kb_account_id\" = 'XXX' OR \"payment_methods\".\"kb_payment_method_id\" = 'XXX') OR \"payment_methods\".\"cc_type\" = 'XXX') OR \"payment_methods\".\"state\" = 'XXX') OR \"payment_methods\".\"zip\" = 'XXX') OR \"payment_methods\".\"cc_first_name\" LIKE '%XXX%') OR \"payment_methods\".\"cc_last_name\" LIKE '%XXX%') OR \"payment_methods\".\"address1\" LIKE '%XXX%') OR \"payment_methods\".\"address2\" LIKE '%XXX%') OR \"payment_methods\".\"city\" LIKE '%XXX%') OR \"payment_methods\".\"country\" LIKE '%XXX%') ORDER BY \"payment_methods\".\"id\""
    Killbill::Plugin::ActiveMerchant::ActiveRecord::PaymentMethod.search_query('XXX').to_sql.should == expected_query

    # Check query with results (search query string)
    expected_query = "SELECT  DISTINCT \"payment_methods\".* FROM \"payment_methods\"  WHERE ((((((((((\"payment_methods\".\"kb_account_id\" = 'XXX' OR \"payment_methods\".\"kb_payment_method_id\" = 'XXX') OR \"payment_methods\".\"cc_type\" = 'XXX') OR \"payment_methods\".\"state\" = 'XXX') OR \"payment_methods\".\"zip\" = 'XXX') OR \"payment_methods\".\"cc_first_name\" LIKE '%XXX%') OR \"payment_methods\".\"cc_last_name\" LIKE '%XXX%') OR \"payment_methods\".\"address1\" LIKE '%XXX%') OR \"payment_methods\".\"address2\" LIKE '%XXX%') OR \"payment_methods\".\"city\" LIKE '%XXX%') OR \"payment_methods\".\"country\" LIKE '%XXX%') ORDER BY \"payment_methods\".\"id\" LIMIT 10 OFFSET 0"
    Killbill::Plugin::ActiveMerchant::ActiveRecord::PaymentMethod.search_query('XXX', 0, 10).to_sql.should == expected_query
  end

  it 'should search all fields' do
    do_search('foo').size.should == 0

    pm = Killbill::Plugin::ActiveMerchant::ActiveRecord::PaymentMethod.create :kb_account_id => '11-22-33-44',
                                                                              :kb_payment_method_id => '55-66-77-88',
                                                                              :cc_first_name => 'ccFirstName',
                                                                              :cc_last_name => 'ccLastName',
                                                                              :cc_type => 'ccType',
                                                                              :cc_exp_month => 10,
                                                                              :cc_exp_year => 11,
                                                                              :cc_last_4 => 1234,
                                                                              :address1 => 'address1',
                                                                              :address2 => 'address2',
                                                                              :city => 'city',
                                                                              :state => 'state',
                                                                              :zip => 'zip',
                                                                              :country => 'country'

    do_search('foo').size.should == 0
    do_search('ccType').size.should == 1
    # Exact match only for cc_last_4
    do_search('123').size.should == 0
    do_search('1234').size.should == 1
    # Test partial match
    do_search('address').size.should == 1
    do_search('Name').size.should == 1

    pm2 = Killbill::Plugin::ActiveMerchant::ActiveRecord::PaymentMethod.create :kb_account_id => '22-33-44-55',
                                                                               :kb_payment_method_id => '66-77-88-99',
                                                                               :cc_first_name => 'ccFirstName',
                                                                               :cc_last_name => 'ccLastName',
                                                                               :cc_type => 'ccType',
                                                                               :cc_exp_month => 10,
                                                                               :cc_exp_year => 11,
                                                                               :cc_last_4 => 1234,
                                                                               :address1 => 'address1',
                                                                               :address2 => 'address2',
                                                                               :city => 'city',
                                                                               :state => 'state',
                                                                               :zip => 'zip',
                                                                               :country => 'country'

    do_search('foo').size.should == 0
    do_search('ccType').size.should == 2
    # Exact match only for cc_last_4
    do_search('123').size.should == 0
    do_search('1234').size.should == 2
    # Test partial match
    do_search('cc').size.should == 2
    do_search('address').size.should == 2
    do_search('Name').size.should == 2
  end

  private

  def do_search(search_key)
    pagination = Killbill::Plugin::ActiveMerchant::ActiveRecord::PaymentMethod.search(search_key)
    pagination.current_offset.should == 0
    results = pagination.iterator.to_a
    pagination.total_nb_records.should == results.size
    results
  end
end
