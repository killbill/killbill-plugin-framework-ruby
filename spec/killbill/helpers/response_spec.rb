require 'spec_helper'

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
    kb_payment_id2               = SecureRandom.uuid
    kb_payment_id3               = SecureRandom.uuid
    kb_payment_transaction_id    = SecureRandom.uuid
    transaction_type             = :PURCHASE
    payment_processor_account_id = 'petit_poucet'
    kb_tenant_id                 = SecureRandom.uuid
    kb_tenant_id2                = SecureRandom.uuid
    success_response             = ::ActiveMerchant::Billing::Response.new(true, 'Message', {}, {
        :authorization => SecureRandom.uuid,
        :avs_result    => ::ActiveMerchant::Billing::AVSResult.new(:code => 'P')
    })
    failure_response             = ::ActiveMerchant::Billing::Response.new(false, 'Message', {}, {
        :authorization => SecureRandom.uuid,
        :avs_result    => ::ActiveMerchant::Billing::AVSResult.new(:code => 'P')
    })

    # Successful response
    response, transaction = ::Killbill::Test::TestResponse.create_response_and_transaction('test', ::Killbill::Test::TestTransaction, api_call, kb_account_id, kb_payment_id, kb_payment_transaction_id, transaction_type, payment_processor_account_id, kb_tenant_id, success_response, 120, 'USD', {}, ::Killbill::Test::TestResponse)
    found_response        = ::Killbill::Test::TestResponse.find(response.id)
    found_response.should == response
    found_response.test_transaction.should == transaction
    found_transaction = ::Killbill::Test::TestTransaction.find(transaction.id)
    found_transaction.should == transaction
    found_transaction.test_response.should == response

    successful_responses = ::Killbill::Test::TestResponse.from_kb_payment_id(::Killbill::Test::TestTransaction, kb_payment_id, kb_tenant_id)
    successful_responses.size.should == 1
    successful_responses[0].should == response

    # Unsuccessful response
    response, transaction = ::Killbill::Test::TestResponse.create_response_and_transaction('test', ::Killbill::Test::TestTransaction, api_call, kb_account_id, kb_payment_id, kb_payment_transaction_id, transaction_type, payment_processor_account_id, kb_tenant_id, failure_response, 120, 'USD', {}, ::Killbill::Test::TestResponse)
    transaction.should be_nil
    found_response = ::Killbill::Test::TestResponse.find(response.id)
    found_response.should == response
    found_response.test_transaction.should be_nil

    ::Killbill::Test::TestResponse.from_kb_payment_id(::Killbill::Test::TestTransaction, kb_payment_id, kb_tenant_id).size == 2

    # Another successful response for the same payment (different transaction)
    ::Killbill::Test::TestResponse.create_response_and_transaction('test', ::Killbill::Test::TestTransaction, api_call, kb_account_id, kb_payment_id, SecureRandom.uuid, transaction_type, payment_processor_account_id, kb_tenant_id, success_response, 120, 'USD', {}, ::Killbill::Test::TestResponse)
    ::Killbill::Test::TestResponse.from_kb_payment_id(::Killbill::Test::TestTransaction, kb_payment_id, kb_tenant_id).size == 3

    # Add other successful responses
    ::Killbill::Test::TestResponse.create_response_and_transaction('test', ::Killbill::Test::TestTransaction, api_call, kb_account_id, kb_payment_id2, SecureRandom.uuid, transaction_type, payment_processor_account_id, kb_tenant_id, success_response, 120, 'USD', {}, ::Killbill::Test::TestResponse)
    ::Killbill::Test::TestResponse.create_response_and_transaction('test', ::Killbill::Test::TestTransaction, api_call, kb_account_id, kb_payment_id3, SecureRandom.uuid, transaction_type, payment_processor_account_id, kb_tenant_id2, success_response, 120, 'USD', {}, ::Killbill::Test::TestResponse)
    ::Killbill::Test::TestResponse.from_kb_payment_id(::Killbill::Test::TestTransaction, kb_payment_id, kb_tenant_id).size == 3
    ::Killbill::Test::TestResponse.from_kb_payment_id(::Killbill::Test::TestTransaction, kb_payment_id2, kb_tenant_id).size == 1
    ::Killbill::Test::TestResponse.from_kb_payment_id(::Killbill::Test::TestTransaction, kb_payment_id3, kb_tenant_id2).size == 1

    # Lookup responses for kb_payment_id
    responses = ::Killbill::Test::TestResponse.responses_from_kb_payment_id(transaction_type, kb_payment_id, kb_tenant_id)
    responses.size.should == 3
    responses[0].success.should be_true
    responses[1].success.should be_false
    responses[2].success.should be_true

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
    ::Killbill::Test::TestResponse.from_kb_payment_id(::Killbill::Test::TestTransaction, SecureRandom.uuid, kb_tenant_id).size.should == 0
    ::Killbill::Test::TestResponse.from_kb_payment_id(::Killbill::Test::TestTransaction, kb_payment_id, SecureRandom.uuid).size.should == 0
    ::Killbill::Test::TestResponse.from_kb_payment_id(::Killbill::Test::TestTransaction, kb_payment_id, kb_tenant_id2).size == 0
    ::Killbill::Test::TestResponse.from_kb_payment_id(::Killbill::Test::TestTransaction, kb_payment_id2, kb_tenant_id2).size == 0
    ::Killbill::Test::TestResponse.from_kb_payment_id(::Killbill::Test::TestTransaction, kb_payment_id3, kb_tenant_id).size == 0
  end

  it 'should filter out sensitive parameter if specified' do
    extra_params = {:email => "test.test", :payer_id => "test"}
    ::Killbill::Test::TestResponse.send(:remove_sensitive_data_and_compact, extra_params)
    extra_params[:email].should be_nil
    extra_params[:payer_id].should == "test"
  end

  it 'should generate the right SQL query' do
    # Check count query (search query numeric)
    expected_query = "SELECT COUNT(DISTINCT #{q('test_responses')}.#{q('id')}) FROM #{q('test_responses')}  WHERE (((#{q('test_responses')}.#{q('kb_payment_id')} = '1234' OR #{q('test_responses')}.#{q('kb_payment_transaction_id')} = '1234') OR #{q('test_responses')}.#{q('message')} = '1234') OR #{q('test_responses')}.#{q('authorization')} = '1234') AND #{q('test_responses')}.#{q('success')} = #{qtrue} AND #{q('test_responses')}.#{q('kb_tenant_id')} = '11-22-33'"
    # Note that Kill Bill will pass a String, even for numeric types
    ::Killbill::Test::TestResponse.search_query('1234', '11-22-33').to_sql.should == expected_query

    # Check query with results (search query numeric)
    expected_query = "SELECT  DISTINCT #{q('test_responses')}.* FROM #{q('test_responses')}  WHERE (((#{q('test_responses')}.#{q('kb_payment_id')} = '1234' OR #{q('test_responses')}.#{q('kb_payment_transaction_id')} = '1234') OR #{q('test_responses')}.#{q('message')} = '1234') OR #{q('test_responses')}.#{q('authorization')} = '1234') AND #{q('test_responses')}.#{q('success')} = #{qtrue} AND #{q('test_responses')}.#{q('kb_tenant_id')} = '11-22-33'  ORDER BY #{q('test_responses')}.#{q('id')} LIMIT 10 OFFSET 0"
    # Note that Kill Bill will pass a String, even for numeric types
    ::Killbill::Test::TestResponse.search_query('1234', '11-22-33', 0, 10).to_sql.should == expected_query

    # Check count query (search query string)
    expected_query = "SELECT COUNT(DISTINCT #{q('test_responses')}.#{q('id')}) FROM #{q('test_responses')}  WHERE (((#{q('test_responses')}.#{q('kb_payment_id')} = 'XXX' OR #{q('test_responses')}.#{q('kb_payment_transaction_id')} = 'XXX') OR #{q('test_responses')}.#{q('message')} = 'XXX') OR #{q('test_responses')}.#{q('authorization')} = 'XXX') AND #{q('test_responses')}.#{q('success')} = #{qtrue} AND #{q('test_responses')}.#{q('kb_tenant_id')} = '11-22-33'"
    ::Killbill::Test::TestResponse.search_query('XXX', '11-22-33').to_sql.should == expected_query

    # Check query with results (search query string)
    expected_query = "SELECT  DISTINCT #{q('test_responses')}.* FROM #{q('test_responses')}  WHERE (((#{q('test_responses')}.#{q('kb_payment_id')} = 'XXX' OR #{q('test_responses')}.#{q('kb_payment_transaction_id')} = 'XXX') OR #{q('test_responses')}.#{q('message')} = 'XXX') OR #{q('test_responses')}.#{q('authorization')} = 'XXX') AND #{q('test_responses')}.#{q('success')} = #{qtrue} AND #{q('test_responses')}.#{q('kb_tenant_id')} = '11-22-33'  ORDER BY #{q('test_responses')}.#{q('id')} LIMIT 10 OFFSET 0"
    ::Killbill::Test::TestResponse.search_query('XXX', '11-22-33', 0, 10).to_sql.should == expected_query
  end

  it 'should search all fields' do
    do_search('foo').size.should == 0

    pm       = ::Killbill::Test::TestResponse.create :api_call      => 'charge',
                                                     :kb_account_id => '55-66-77-88',
                                                     :kb_payment_id => '11-22-33-44',
                                                     :kb_tenant_id  => '11-22-33',
                                                     :success       => true,
                                                     :created_at    => Time.now.utc,
                                                     :updated_at    => Time.now.utc

    # Not successful
    ignored2 = ::Killbill::Test::TestResponse.create :api_call      => 'charge',
                                                     :kb_account_id => '55-66-77-88',
                                                     :kb_payment_id => pm.kb_payment_id,
                                                     :kb_tenant_id  => '11-22-33',
                                                     :success       => false,
                                                     :created_at    => Time.now.utc,
                                                     :updated_at    => Time.now.utc

    do_search(pm.kb_payment_id).size.should == 1

    pm2 = ::Killbill::Test::TestResponse.create :api_call      => 'charge',
                                                :kb_account_id => '55-66-77-88',
                                                :kb_payment_id => pm.kb_payment_id,
                                                :kb_tenant_id  => '11-22-33',
                                                :success       => true,
                                                :created_at    => Time.now.utc,
                                                :updated_at    => Time.now.utc

    do_search(pm.kb_payment_id).size.should == 2
  end

  context 'performance' do
    require 'benchmark'

    it 'creates the transaction association fast' do
      api_call = 'for debugging only'
      kb_account_id = SecureRandom.uuid
      kb_payment_id = SecureRandom.uuid
      kb_payment_transaction_id = SecureRandom.uuid
      transaction_type = :PURCHASE
      payment_processor_account_id = SecureRandom.uuid
      kb_tenant_id = SecureRandom.uuid
      success_response = ::ActiveMerchant::Billing::Response.new(true, 'Message')

      # Warm-up the stack
      response, transaction = ::Killbill::Test::TestResponse.create_response_and_transaction('test', ::Killbill::Test::TestTransaction, api_call, kb_account_id, kb_payment_id, kb_payment_transaction_id, transaction_type, payment_processor_account_id, kb_tenant_id, success_response, 120, 'USD', {}, ::Killbill::Test::TestResponse)

      runs = (ENV['NB_RUNS'] || 2).to_i

      time = Benchmark::Tms.new
      Benchmark.bm do |x|
        runs.times do |n|
          time += x.report("run ##{n}:") do
            response, transaction = ::Killbill::Test::TestResponse.create_response_and_transaction('test', ::Killbill::Test::TestTransaction, api_call, kb_account_id, kb_payment_id, kb_payment_transaction_id, transaction_type, payment_processor_account_id, kb_tenant_id, success_response, 120, 'USD', {}, ::Killbill::Test::TestResponse)

            response.id.should_not be_nil
            response.created_at.should_not be_nil
            response.updated_at.should_not be_nil

            transaction.id.should_not be_nil
            transaction.created_at.should_not be_nil
            transaction.updated_at.should_not be_nil
            transaction.test_response_id.should == response.id
          end
        end
      end

      puts " total:#{time.to_s}"
      puts "   avg:#{(time/runs).to_s}"
    end
  end

  private

  def do_search(search_key)
    pagination = ::Killbill::Test::TestResponse.search(search_key, '11-22-33')
    pagination.current_offset.should == 0
    results = pagination.iterator.to_a
    pagination.total_nb_records.should == results.size
    results
  end

  def q(arg)
    ::ActiveRecord::Base.connection.quote_column_name(arg)
  end

  def qtrue
    ::ActiveRecord::Base.connection.quoted_true
  end
end
