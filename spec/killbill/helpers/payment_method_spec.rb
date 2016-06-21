require 'spec_helper'

describe Killbill::Plugin::ActiveMerchant::ActiveRecord::PaymentMethod do

  before :each do
    ::Killbill::Test::TestPaymentMethod.delete_all
  end

  it 'should construct payment methods correctly' do
    kb_account_id        = SecureRandom.uuid
    kb_payment_method_id = SecureRandom.uuid
    kb_tenant_id         = SecureRandom.uuid
    response             = ::ActiveMerchant::Billing::Response.new(true, nil, {}, {:authorization => SecureRandom.uuid})
    options              = {
        :billing_address => {
            :address1 => SecureRandom.uuid,
            :address2 => SecureRandom.uuid,
            :city     => SecureRandom.uuid,
            :state    => SecureRandom.uuid,
            :zip      => SecureRandom.uuid,
            :country  => SecureRandom.uuid
        }
    }
    cc                   = ::ActiveMerchant::Billing::CreditCard.new(
        :first_name => 'Steve',
        :last_name  => 'Smith',
        :month      => '9',
        :year       => '2010',
        :brand      => 'visa',
        :number     => '4242424242424242'
    )
    token                = SecureRandom.uuid

    # Test storage of CC details
    pm                   = ::Killbill::Test::TestPaymentMethod.from_response(kb_account_id, kb_payment_method_id, kb_tenant_id, cc, response, options, {}, ::Killbill::Test::TestPaymentMethod)
    pm.kb_account_id.should == kb_account_id
    pm.kb_payment_method_id.should == kb_payment_method_id
    pm.kb_tenant_id.should == kb_tenant_id
    pm.token.should == response.authorization
    pm.cc_first_name.should == cc.first_name
    pm.cc_last_name.should == cc.last_name
    pm.cc_type.should == cc.brand
    pm.cc_exp_month.should == cc.month
    pm.cc_exp_year.should == cc.year
    pm.cc_last_4.should == cc.last_digits
    pm.address1.should == options[:billing_address][:address1]
    pm.address2.should == options[:billing_address][:address2]
    pm.city.should == options[:billing_address][:city]
    pm.state.should == options[:billing_address][:state]
    pm.zip.should == options[:billing_address][:zip]
    pm.country.should == options[:billing_address][:country]
    # Verify conversions
    verify_conversion_to_kb_objects(pm, kb_account_id, kb_payment_method_id, response.authorization)

    # Test storage of CC details with no billing address
    pm = ::Killbill::Test::TestPaymentMethod.from_response(kb_account_id, kb_payment_method_id, kb_tenant_id, cc, response, {}, {}, ::Killbill::Test::TestPaymentMethod)
    pm.kb_account_id.should == kb_account_id
    pm.kb_payment_method_id.should == kb_payment_method_id
    pm.kb_tenant_id.should == kb_tenant_id
    pm.token.should == response.authorization
    pm.cc_first_name.should == cc.first_name
    pm.cc_last_name.should == cc.last_name
    pm.cc_type.should == cc.brand
    pm.cc_exp_month.should == cc.month
    pm.cc_exp_year.should == cc.year
    pm.cc_last_4.should == cc.last_digits
    pm.address1.should be_nil
    pm.address2.should be_nil
    pm.city.should be_nil
    pm.state.should be_nil
    pm.zip.should be_nil
    pm.country.should be_nil
    # Verify conversions
    verify_conversion_to_kb_objects(pm, kb_account_id, kb_payment_method_id, response.authorization)

    # Test storage of token
    pm = ::Killbill::Test::TestPaymentMethod.from_response(kb_account_id, kb_payment_method_id, kb_tenant_id, token, response, options, {}, ::Killbill::Test::TestPaymentMethod)
    pm.kb_account_id.should == kb_account_id
    pm.kb_payment_method_id.should == kb_payment_method_id
    pm.kb_tenant_id.should == kb_tenant_id
    pm.token.should == token
    pm.cc_first_name.should be_nil
    pm.cc_last_name.should be_nil
    pm.cc_type.should be_nil
    pm.cc_exp_month.should be_nil
    pm.cc_exp_year.should be_nil
    pm.cc_last_4.should be_nil
    pm.address1.should == options[:billing_address][:address1]
    pm.address2.should == options[:billing_address][:address2]
    pm.city.should == options[:billing_address][:city]
    pm.state.should == options[:billing_address][:state]
    pm.zip.should == options[:billing_address][:zip]
    pm.country.should == options[:billing_address][:country]
    # Verify conversions
    verify_conversion_to_kb_objects(pm, kb_account_id, kb_payment_method_id, token)

    # Test storage of token with no billing address
    pm = ::Killbill::Test::TestPaymentMethod.from_response(kb_account_id, kb_payment_method_id, kb_tenant_id, token, response, {}, {}, ::Killbill::Test::TestPaymentMethod)
    pm.kb_account_id.should == kb_account_id
    pm.kb_payment_method_id.should == kb_payment_method_id
    pm.kb_tenant_id.should == kb_tenant_id
    pm.token.should == token
    pm.cc_first_name.should be_nil
    pm.cc_last_name.should be_nil
    pm.cc_type.should be_nil
    pm.cc_exp_month.should be_nil
    pm.cc_exp_year.should be_nil
    pm.cc_last_4.should be_nil
    pm.address1.should be_nil
    pm.address2.should be_nil
    pm.city.should be_nil
    pm.state.should be_nil
    pm.zip.should be_nil
    pm.country.should be_nil
    # Verify conversions
    verify_conversion_to_kb_objects(pm, kb_account_id, kb_payment_method_id, token)
  end

  it 'should store and retrieve payment methods correctly' do
    kb_account_id        = SecureRandom.uuid
    kb_payment_method_id = SecureRandom.uuid
    kb_tenant_id         = SecureRandom.uuid
    response             = ::ActiveMerchant::Billing::Response.new(true, nil, {}, {:authorization => SecureRandom.uuid})
    token                = SecureRandom.uuid
    pm                   = ::Killbill::Test::TestPaymentMethod.from_response(kb_account_id, kb_payment_method_id, kb_tenant_id, token, response, {}, {}, ::Killbill::Test::TestPaymentMethod)
    pm.save!

    # Retrieve by account id
    ::Killbill::Test::TestPaymentMethod.from_kb_account_id(kb_account_id, nil).size.should == 0
    ::Killbill::Test::TestPaymentMethod.from_kb_account_id(kb_account_id, SecureRandom.uuid).size.should == 0
    ::Killbill::Test::TestPaymentMethod.from_kb_account_id(SecureRandom.uuid, kb_tenant_id).size.should == 0
    pms = ::Killbill::Test::TestPaymentMethod.from_kb_account_id(kb_account_id, kb_tenant_id)
    pms.size.should == 1
    pms[0].kb_payment_method_id.should == kb_payment_method_id

    # Retrieve by payment method id
    expect { ::Killbill::Test::TestPaymentMethod.from_kb_payment_method_id(kb_payment_method_id, nil) }.to raise_error
    expect { ::Killbill::Test::TestPaymentMethod.from_kb_payment_method_id(kb_payment_method_id, SecureRandom.uuid) }.to raise_error
    expect { ::Killbill::Test::TestPaymentMethod.from_kb_payment_method_id(SecureRandom.uuid, kb_tenant_id) }.to raise_error
    ::Killbill::Test::TestPaymentMethod.from_kb_payment_method_id(kb_payment_method_id, kb_tenant_id).kb_payment_method_id.should == kb_payment_method_id

    # Retrieve by account id and token
    pms = ::Killbill::Test::TestPaymentMethod.from_kb_account_id_and_token(token, kb_account_id, kb_tenant_id)
    pms.size.should == 1
    pms[0].kb_payment_method_id.should == kb_payment_method_id

    # Delete the payment method and verify we cannot find it anymore
    ::Killbill::Test::TestPaymentMethod.mark_as_deleted!(kb_payment_method_id, kb_tenant_id)
    ::Killbill::Test::TestPaymentMethod.from_kb_account_id(kb_account_id, kb_tenant_id).size.should == 0
    expect { ::Killbill::Test::TestPaymentMethod.from_kb_payment_method_id(kb_payment_method_id, kb_tenant_id) }.to raise_error
  end

  it 'should handle non-numeric credit card values' do
    pm = ::Killbill::Test::TestPaymentMethod.create :kb_account_id        => '11-22-33-44',
                                                    :kb_payment_method_id => '55-66-77-88',
                                                    :kb_tenant_id         => '11-22-33',
                                                    :cc_first_name        => 'ccFirstName',
                                                    :cc_last_name         => 'ccLastName',
                                                    :cc_type              => 'ccType',
                                                    :cc_exp_month         => '07',
                                                    :cc_exp_year          => '01',
                                                    :cc_last_4            => '0001',
                                                    :cc_number            => 'some-proprietary-token-format',
                                                    :address1             => 'address1',
                                                    :address2             => 'address2',
                                                    :city                 => 'city',
                                                    :state                => 'state',
                                                    :zip                  => 'zip',
                                                    :country              => 'country',
                                                    :created_at           => Time.now.utc,
                                                    :updated_at           => Time.now.utc

    pm.created_at.should_not be_nil
    pm.updated_at.should_not be_nil

    pm = ::Killbill::Test::TestPaymentMethod.from_kb_payment_method_id(pm.kb_payment_method_id, pm.kb_tenant_id)
    pm.cc_exp_month.should == '07'
    pm.cc_exp_year.should == '01'
    pm.cc_last_4.should == '0001'
    pm.cc_number.should == 'some-proprietary-token-format'
  end

  it 'should generate the right SQL query' do
    # Check count query (search query numeric)
    expected_query = /SELECT COUNT\(DISTINCT #{q('test_payment_methods')}.#{q('id')}\) FROM #{q('test_payment_methods')}  WHERE \(\(\(\(\(\(\(\(\(\(\(\(\(\(#{q('test_payment_methods')}.#{q('kb_account_id')} = '1234' OR #{q('test_payment_methods')}.#{q('kb_payment_method_id')} = '1234'\) OR #{q('test_payment_methods')}.#{q('token')} = '1234'\) OR #{q('test_payment_methods')}.#{q('cc_type')} = '1234'\) OR #{q('test_payment_methods')}.#{q('state')} = '1234'\) OR #{q('test_payment_methods')}.#{q('zip')} = '1234'\) OR #{q('test_payment_methods')}.#{q('cc_first_name')} I?LIKE '%1234%'\) OR #{q('test_payment_methods')}.#{q('cc_last_name')} I?LIKE '%1234%'\) OR #{q('test_payment_methods')}.#{q('address1')} I?LIKE '%1234%'\) OR #{q('test_payment_methods')}.#{q('address2')} I?LIKE '%1234%'\) OR #{q('test_payment_methods')}.#{q('city')} I?LIKE '%1234%'\) OR #{q('test_payment_methods')}.#{q('country')} I?LIKE '%1234%'\) OR #{q('test_payment_methods')}.#{q('cc_exp_month')} = '1234'\) OR #{q('test_payment_methods')}.#{q('cc_exp_year')} = '1234'\) OR #{q('test_payment_methods')}.#{q('cc_last_4')} = '1234'\) AND #{q('test_payment_methods')}.#{q('kb_tenant_id')} = '11-22-33'/
    # Note that Kill Bill will pass a String, even for numeric types
    ::Killbill::Test::TestPaymentMethod.search_query('1234', '11-22-33').to_sql.should match(expected_query)

    # Check query with results (search query numeric)
    expected_query = /SELECT  DISTINCT #{q('test_payment_methods')}.* FROM #{q('test_payment_methods')}  WHERE \(\(\(\(\(\(\(\(\(\(\(\(\(\(#{q('test_payment_methods')}.#{q('kb_account_id')} = '1234' OR #{q('test_payment_methods')}.#{q('kb_payment_method_id')} = '1234'\) OR #{q('test_payment_methods')}.#{q('token')} = '1234'\) OR #{q('test_payment_methods')}.#{q('cc_type')} = '1234'\) OR #{q('test_payment_methods')}.#{q('state')} = '1234'\) OR #{q('test_payment_methods')}.#{q('zip')} = '1234'\) OR #{q('test_payment_methods')}.#{q('cc_first_name')} I?LIKE '%1234%'\) OR #{q('test_payment_methods')}.#{q('cc_last_name')} I?LIKE '%1234%'\) OR #{q('test_payment_methods')}.#{q('address1')} I?LIKE '%1234%'\) OR #{q('test_payment_methods')}.#{q('address2')} I?LIKE '%1234%'\) OR #{q('test_payment_methods')}.#{q('city')} I?LIKE '%1234%'\) OR #{q('test_payment_methods')}.#{q('country')} I?LIKE '%1234%'\) OR #{q('test_payment_methods')}.#{q('cc_exp_month')} = '1234'\) OR #{q('test_payment_methods')}.#{q('cc_exp_year')} = '1234'\) OR #{q('test_payment_methods')}.#{q('cc_last_4')} = '1234'\) AND #{q('test_payment_methods')}.#{q('kb_tenant_id')} = '11-22-33'  ORDER BY #{q('test_payment_methods')}.#{q('id')} LIMIT 10 OFFSET 0/
    # Note that Kill Bill will pass a String, even for numeric types
    ::Killbill::Test::TestPaymentMethod.search_query('1234', '11-22-33', 0, 10).to_sql.should match(expected_query)

    # Check count query (search query string)
    expected_query = /SELECT COUNT\(DISTINCT #{q('test_payment_methods')}.#{q('id')}\) FROM #{q('test_payment_methods')}  WHERE \(\(\(\(\(\(\(\(\(\(\(#{q('test_payment_methods')}.#{q('kb_account_id')} = 'XXX' OR #{q('test_payment_methods')}.#{q('kb_payment_method_id')} = 'XXX'\) OR #{q('test_payment_methods')}.#{q('token')} = 'XXX'\) OR #{q('test_payment_methods')}.#{q('cc_type')} = 'XXX'\) OR #{q('test_payment_methods')}.#{q('state')} = 'XXX'\) OR #{q('test_payment_methods')}.#{q('zip')} = 'XXX'\) OR #{q('test_payment_methods')}.#{q('cc_first_name')} I?LIKE '%XXX%'\) OR #{q('test_payment_methods')}.#{q('cc_last_name')} I?LIKE '%XXX%'\) OR #{q('test_payment_methods')}.#{q('address1')} I?LIKE '%XXX%'\) OR #{q('test_payment_methods')}.#{q('address2')} I?LIKE '%XXX%'\) OR #{q('test_payment_methods')}.#{q('city')} I?LIKE '%XXX%'\) OR #{q('test_payment_methods')}.#{q('country')} I?LIKE '%XXX%'\) AND #{q('test_payment_methods')}.#{q('kb_tenant_id')} = '11-22-33'/
    ::Killbill::Test::TestPaymentMethod.search_query('XXX', '11-22-33').to_sql.should match(expected_query)

    # Check query with results (search query string)
    expected_query = /SELECT  DISTINCT #{q('test_payment_methods')}.* FROM #{q('test_payment_methods')}  WHERE \(\(\(\(\(\(\(\(\(\(\(#{q('test_payment_methods')}.#{q('kb_account_id')} = 'XXX' OR #{q('test_payment_methods')}.#{q('kb_payment_method_id')} = 'XXX'\) OR #{q('test_payment_methods')}.#{q('token')} = 'XXX'\) OR #{q('test_payment_methods')}.#{q('cc_type')} = 'XXX'\) OR #{q('test_payment_methods')}.#{q('state')} = 'XXX'\) OR #{q('test_payment_methods')}.#{q('zip')} = 'XXX'\) OR #{q('test_payment_methods')}.#{q('cc_first_name')} I?LIKE '%XXX%'\) OR #{q('test_payment_methods')}.#{q('cc_last_name')} I?LIKE '%XXX%'\) OR #{q('test_payment_methods')}.#{q('address1')} I?LIKE '%XXX%'\) OR #{q('test_payment_methods')}.#{q('address2')} I?LIKE '%XXX%'\) OR #{q('test_payment_methods')}.#{q('city')} I?LIKE '%XXX%'\) OR #{q('test_payment_methods')}.#{q('country')} I?LIKE '%XXX%'\) AND #{q('test_payment_methods')}.#{q('kb_tenant_id')} = '11-22-33'  ORDER BY #{q('test_payment_methods')}.#{q('id')} LIMIT 10 OFFSET 0/
    ::Killbill::Test::TestPaymentMethod.search_query('XXX', '11-22-33', 0, 10).to_sql.should match(expected_query)
  end

  it 'should search all fields' do
    do_search('foo').size.should == 0

    pm = ::Killbill::Test::TestPaymentMethod.create :kb_account_id        => '11-22-33-44',
                                                    :kb_payment_method_id => '55-66-77-88',
                                                    :kb_tenant_id         => '11-22-33',
                                                    :cc_first_name        => 'ccFirstName',
                                                    :cc_last_name         => 'ccLastName',
                                                    :cc_type              => 'ccType',
                                                    :cc_exp_month         => 10,
                                                    :cc_exp_year          => 11,
                                                    :cc_last_4            => 1234,
                                                    :address1             => 'address1',
                                                    :address2             => 'address2',
                                                    :city                 => 'city',
                                                    :state                => 'state',
                                                    :zip                  => 'zip',
                                                    :country              => 'country',
                                                    :created_at           => Time.now.utc,
                                                    :updated_at           => Time.now.utc

    do_search('foo').size.should == 0
    do_search('ccType').size.should == 1
    # Exact match only for cc_last_4
    do_search('123').size.should == 0
    do_search('1234').size.should == 1
    # Test partial match
    do_search('address').size.should == 1
    do_search('Name').size.should == 1

    pm2 = ::Killbill::Test::TestPaymentMethod.create :kb_account_id        => '22-33-44-55',
                                                     :kb_payment_method_id => '66-77-88-99',
                                                     :kb_tenant_id         => '11-22-33',
                                                     :cc_first_name        => 'ccFirstName',
                                                     :cc_last_name         => 'ccLastName',
                                                     :cc_type              => 'ccType',
                                                     :cc_exp_month         => 10,
                                                     :cc_exp_year          => 11,
                                                     :cc_last_4            => 1234,
                                                     :address1             => 'address1',
                                                     :address2             => 'address2',
                                                     :city                 => 'city',
                                                     :state                => 'state',
                                                     :zip                  => 'zip',
                                                     :country              => 'country',
                                                     :created_at           => Time.now.utc,
                                                     :updated_at           => Time.now.utc

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
    pagination = ::Killbill::Test::TestPaymentMethod.search(search_key, '11-22-33')
    pagination.current_offset.should == 0
    results = pagination.iterator.to_a
    pagination.total_nb_records.should == results.size
    results
  end

  def verify_conversion_to_kb_objects(pm, kb_account_id, kb_payment_method_id, external_payment_method_id)
    # Verify conversion to PaymentMethodPlugin
    pmp = pm.to_payment_method_plugin
    pmp.kb_payment_method_id.should == kb_payment_method_id
    pmp.external_payment_method_id.should == external_payment_method_id
    pmp.properties.size.should == 15

    # Verify conversion to PaymentMethodInfoPlugin
    pmip = pm.to_payment_method_info_plugin
    pmip.account_id.should == kb_account_id
    pmip.payment_method_id.should == kb_payment_method_id
    pmip.external_payment_method_id.should == external_payment_method_id
  end

  def q(arg)
    ::ActiveRecord::Base.connection.quote_column_name(arg)
  end
end
