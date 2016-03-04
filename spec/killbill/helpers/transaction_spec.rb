require 'spec_helper'

describe Killbill::Plugin::ActiveMerchant::ActiveRecord::Transaction do

  before :each do
    ::Killbill::Test::TestTransaction.delete_all
  end

  # https://github.com/killbill/killbill-plugin-framework-ruby/issues/51
  it 'always finds a transaction for refund' do
    api_call        = 'for debugging only'
    amount_in_cents = 1242
    currency        = :USD
    kb_account_id   = SecureRandom.uuid
    kb_tenant_id    = SecureRandom.uuid
    kb_payment_id   = SecureRandom.uuid

    auth_tx = create_transaction(api_call, kb_payment_id, SecureRandom.uuid, :AUTHORIZE, amount_in_cents, currency, kb_account_id, kb_tenant_id)
    ::Killbill::Test::TestTransaction.find_candidate_transaction_for_refund(kb_payment_id, kb_tenant_id).id.should == auth_tx.id

    create_transaction(api_call, kb_payment_id, SecureRandom.uuid, :CAPTURE, amount_in_cents, currency, kb_account_id, kb_tenant_id)
    ::Killbill::Test::TestTransaction.find_candidate_transaction_for_refund(kb_payment_id, kb_tenant_id).id.should == auth_tx.id

    create_transaction(api_call, kb_payment_id, SecureRandom.uuid, :REFUND, amount_in_cents, currency, kb_account_id, kb_tenant_id)
    ::Killbill::Test::TestTransaction.find_candidate_transaction_for_refund(kb_payment_id, kb_tenant_id).id.should == auth_tx.id

    create_transaction(api_call, kb_payment_id, SecureRandom.uuid, :REFUND, amount_in_cents, currency, kb_account_id, kb_tenant_id)
    ::Killbill::Test::TestTransaction.find_candidate_transaction_for_refund(kb_payment_id, kb_tenant_id).id.should == auth_tx.id
  end

  # https://github.com/killbill/killbill-plugin-framework-ruby/issues/53
  it 'finds the right transaction to void' do
    api_call        = 'for debugging only'
    amount_in_cents = 1242
    currency        = :USD
    kb_account_id   = SecureRandom.uuid
    kb_tenant_id    = SecureRandom.uuid
    kb_payment_id   = SecureRandom.uuid

    auth_tx = create_transaction(api_call, kb_payment_id, SecureRandom.uuid, :AUTHORIZE, amount_in_cents, currency, kb_account_id, kb_tenant_id)
    ::Killbill::Test::TestTransaction.find_candidate_transaction_for_void(kb_payment_id, kb_tenant_id).id.should == auth_tx.id

    capture_tx1 = create_transaction(api_call, kb_payment_id, SecureRandom.uuid, :CAPTURE, amount_in_cents, currency, kb_account_id, kb_tenant_id)
    ::Killbill::Test::TestTransaction.find_candidate_transaction_for_void(kb_payment_id, kb_tenant_id).id.should == capture_tx1.id
    ::Killbill::Test::TestTransaction.find_candidate_transaction_for_void(kb_payment_id, kb_tenant_id, :AUTHORIZE).id.should == auth_tx.id

    # Void the first capture
    create_transaction(api_call, kb_payment_id, SecureRandom.uuid, :VOID, nil, nil, kb_account_id, kb_tenant_id)
    ::Killbill::Test::TestTransaction.find_candidate_transaction_for_void(kb_payment_id, kb_tenant_id).id.should == auth_tx.id

    capture_tx2 = create_transaction(api_call, kb_payment_id, SecureRandom.uuid, :CAPTURE, amount_in_cents, currency, kb_account_id, kb_tenant_id)
    ::Killbill::Test::TestTransaction.find_candidate_transaction_for_void(kb_payment_id, kb_tenant_id).id.should == capture_tx2.id
    ::Killbill::Test::TestTransaction.find_candidate_transaction_for_void(kb_payment_id, kb_tenant_id, :CAPTURE).id.should == capture_tx2.id
    ::Killbill::Test::TestTransaction.find_candidate_transaction_for_void(kb_payment_id, kb_tenant_id, :AUTHORIZE).id.should == auth_tx.id

    capture_tx3 = create_transaction(api_call, kb_payment_id, SecureRandom.uuid, :CAPTURE, amount_in_cents, currency, kb_account_id, kb_tenant_id)
    ::Killbill::Test::TestTransaction.find_candidate_transaction_for_void(kb_payment_id, kb_tenant_id).id.should == capture_tx3.id
    ::Killbill::Test::TestTransaction.find_candidate_transaction_for_void(kb_payment_id, kb_tenant_id, :CAPTURE).id.should == capture_tx3.id
    ::Killbill::Test::TestTransaction.find_candidate_transaction_for_void(kb_payment_id, kb_tenant_id, :AUTHORIZE).id.should == auth_tx.id

    # Void the third capture
    create_transaction(api_call, kb_payment_id, SecureRandom.uuid, :VOID, nil, nil, kb_account_id, kb_tenant_id)
    ::Killbill::Test::TestTransaction.find_candidate_transaction_for_void(kb_payment_id, kb_tenant_id).id.should == capture_tx2.id
    ::Killbill::Test::TestTransaction.find_candidate_transaction_for_void(kb_payment_id, kb_tenant_id, :CAPTURE).id.should == capture_tx2.id
    ::Killbill::Test::TestTransaction.find_candidate_transaction_for_void(kb_payment_id, kb_tenant_id, :AUTHORIZE).id.should == auth_tx.id

    # Void the second capture
    create_transaction(api_call, kb_payment_id, SecureRandom.uuid, :VOID, nil, nil, kb_account_id, kb_tenant_id)
    ::Killbill::Test::TestTransaction.find_candidate_transaction_for_void(kb_payment_id, kb_tenant_id).id.should == auth_tx.id

    # Void the authorization
    create_transaction(api_call, kb_payment_id, SecureRandom.uuid, :VOID, nil, nil, kb_account_id, kb_tenant_id)
    ::Killbill::Test::TestTransaction.find_candidate_transaction_for_void(kb_payment_id, kb_tenant_id).should be_nil
  end

  it 'should store and retrieve transactions correctly' do
    api_call        = 'for debugging only'
    amount_in_cents = 1242
    currency        = :USD
    kb_account_id   = SecureRandom.uuid
    kb_tenant_id    = SecureRandom.uuid

    kb_payment_id1             = SecureRandom.uuid
    kb_payment_id2             = SecureRandom.uuid
    kb_payment_transaction_id1 = SecureRandom.uuid
    kb_payment_transaction_id2 = SecureRandom.uuid
    kb_payment_transaction_id3 = SecureRandom.uuid
    kb_payment_transaction_id4 = SecureRandom.uuid
    kb_payment_transaction_id5 = SecureRandom.uuid
    transaction_type1          = :AUTHORIZE
    transaction_type2          = :CAPTURE
    transaction_type3          = :CAPTURE
    transaction_type4          = :PURCHASE
    transaction_type5          = :REFUND

    create_transaction(api_call, kb_payment_id1, kb_payment_transaction_id1, transaction_type1, amount_in_cents, currency, kb_account_id, kb_tenant_id)
    create_transaction(api_call, kb_payment_id1, kb_payment_transaction_id2, transaction_type2, amount_in_cents, currency, kb_account_id, kb_tenant_id)
    create_transaction(api_call, kb_payment_id1, kb_payment_transaction_id3, transaction_type3, amount_in_cents, currency, kb_account_id, kb_tenant_id)
    create_transaction(api_call, kb_payment_id2, kb_payment_transaction_id4, transaction_type4, amount_in_cents, currency, kb_account_id, kb_tenant_id)
    create_transaction(api_call, kb_payment_id2, kb_payment_transaction_id5, transaction_type5, amount_in_cents, currency, kb_account_id, kb_tenant_id)

    ::Killbill::Test::TestTransaction.transactions_from_kb_payment_id(kb_payment_id1, nil).size.should == 0
    ::Killbill::Test::TestTransaction.transactions_from_kb_payment_id(kb_payment_id1, SecureRandom.uuid).size.should == 0
    ::Killbill::Test::TestTransaction.transactions_from_kb_payment_id(SecureRandom.uuid, kb_tenant_id).size.should == 0

    # Lookup transactions for kb_payment_id1
    ts = ::Killbill::Test::TestTransaction.transactions_from_kb_payment_id(kb_payment_id1, kb_tenant_id)
    ts.size.should == 3
    ts[0].kb_payment_transaction_id.should == kb_payment_transaction_id1
    ts[1].kb_payment_transaction_id.should == kb_payment_transaction_id2
    ts[2].kb_payment_transaction_id.should == kb_payment_transaction_id3

    # Lookup transactions for kb_payment_id2
    ts = ::Killbill::Test::TestTransaction.transactions_from_kb_payment_id(kb_payment_id2, kb_tenant_id)
    ts.size.should == 2
    ts[0].kb_payment_transaction_id.should == kb_payment_transaction_id4
    ts[1].kb_payment_transaction_id.should == kb_payment_transaction_id5

    # Lookup AUTH for kb_payment_id1
    ts = ::Killbill::Test::TestTransaction.authorizes_from_kb_payment_id(kb_payment_id1, kb_tenant_id)
    ts.size.should == 1
    ts[0].kb_payment_transaction_id.should == kb_payment_transaction_id1
    ts = ::Killbill::Test::TestTransaction.authorizations_from_kb_payment_id(kb_payment_id1, kb_tenant_id)
    ts.size.should == 1
    ts[0].kb_payment_transaction_id.should == kb_payment_transaction_id1

    # Lookup CAPTURE for kb_payment_id1
    ts = ::Killbill::Test::TestTransaction.captures_from_kb_payment_id(kb_payment_id1, kb_tenant_id)
    ts.size.should == 2
    ts[0].kb_payment_transaction_id.should == kb_payment_transaction_id2
    ts[1].kb_payment_transaction_id.should == kb_payment_transaction_id3

    # Lookup PURCHASE for kb_payment_id1
    ::Killbill::Test::TestTransaction.purchases_from_kb_payment_id(kb_payment_id1, kb_tenant_id).size.should == 0

    # Lookup CREDIT for kb_payment_id1
    ::Killbill::Test::TestTransaction.credits_from_kb_payment_id(kb_payment_id1, kb_tenant_id).size.should == 0

    # Lookup REFUND for kb_payment_id1
    ::Killbill::Test::TestTransaction.refunds_from_kb_payment_id(kb_payment_id1, kb_tenant_id).size.should == 0

    # Lookup VOID for kb_payment_id1
    ::Killbill::Test::TestTransaction.voids_from_kb_payment_id(kb_payment_id1, kb_tenant_id).size.should == 0

    # Lookup AUTH for kb_payment_id2
    ::Killbill::Test::TestTransaction.authorizes_from_kb_payment_id(kb_payment_id2, kb_tenant_id).size.should == 0
    ::Killbill::Test::TestTransaction.authorizations_from_kb_payment_id(kb_payment_id2, kb_tenant_id).size.should == 0

    # Lookup CAPTURE for kb_payment_id2
    ::Killbill::Test::TestTransaction.captures_from_kb_payment_id(kb_payment_id2, kb_tenant_id).size.should == 0

    # Lookup PURCHASE for kb_payment_id2
    ts = ::Killbill::Test::TestTransaction.purchases_from_kb_payment_id(kb_payment_id2, kb_tenant_id)
    ts.size.should == 1
    ts[0].kb_payment_transaction_id.should == kb_payment_transaction_id4

    # Lookup CREDIT for kb_payment_id2
    ::Killbill::Test::TestTransaction.credits_from_kb_payment_id(kb_payment_id2, kb_tenant_id).size.should == 0

    # Lookup REFUND for kb_payment_id2
    ts = ::Killbill::Test::TestTransaction.refunds_from_kb_payment_id(kb_payment_id2, kb_tenant_id)
    ts.size.should == 1
    ts[0].kb_payment_transaction_id.should == kb_payment_transaction_id5

    # Lookup VOID for kb_payment_id2
    ::Killbill::Test::TestTransaction.voids_from_kb_payment_id(kb_payment_id1, kb_tenant_id).size.should == 0

    # Lookup individual transactions
    ::Killbill::Test::TestTransaction.from_kb_payment_transaction_id(kb_payment_transaction_id1, SecureRandom.uuid).should be_nil
    ::Killbill::Test::TestTransaction.from_kb_payment_transaction_id(SecureRandom.uuid, kb_tenant_id).should be_nil
    ::Killbill::Test::TestTransaction.from_kb_payment_transaction_id(kb_payment_transaction_id1, kb_tenant_id).transaction_type.should == 'AUTHORIZE'
    ::Killbill::Test::TestTransaction.from_kb_payment_transaction_id(kb_payment_transaction_id2, kb_tenant_id).transaction_type.should == 'CAPTURE'
    ::Killbill::Test::TestTransaction.from_kb_payment_transaction_id(kb_payment_transaction_id3, kb_tenant_id).transaction_type.should == 'CAPTURE'
    ::Killbill::Test::TestTransaction.from_kb_payment_transaction_id(kb_payment_transaction_id4, kb_tenant_id).transaction_type.should == 'PURCHASE'
    ::Killbill::Test::TestTransaction.from_kb_payment_transaction_id(kb_payment_transaction_id5, kb_tenant_id).transaction_type.should == 'REFUND'
  end

  private

  def create_transaction(api_call, kb_payment_id, kb_payment_transaction_id, transaction_type, amount_in_cents, currency, kb_account_id, kb_tenant_id)
    ::Killbill::Test::TestTransaction.create(:api_call                  => api_call,
                                             :kb_payment_id             => kb_payment_id,
                                             :kb_payment_transaction_id => kb_payment_transaction_id,
                                             :transaction_type          => transaction_type,
                                             :amount_in_cents           => amount_in_cents,
                                             :currency                  => currency,
                                             :kb_account_id             => kb_account_id,
                                             :kb_tenant_id              => kb_tenant_id,
                                             :test_response_id          => 0,
                                             :created_at                => Time.now.utc,
                                             :updated_at                => Time.now.utc)
  end
end
