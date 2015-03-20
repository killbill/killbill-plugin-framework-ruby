require 'spec_helper'

describe Killbill::Plugin::ActiveMerchant::ActiveRecord do

  before(:all) do
    ::Killbill::Test::TestPaymentMethod.delete_all
  end

  it 'should stream results per batch' do
    1.upto(35) do
      ::Killbill::Test::TestPaymentMethod.create(:kb_account_id        => SecureRandom.uuid,
                                                 :kb_payment_method_id => SecureRandom.uuid,
                                                 :kb_tenant_id         => SecureRandom.uuid,
                                                 :token                => SecureRandom.uuid,
                                                 :created_at           => Time.now.utc,
                                                 :updated_at           => Time.now.utc)
    end
    ::Killbill::Test::TestPaymentMethod.count.should == 35

    enum = ::Killbill::Plugin::ActiveMerchant::ActiveRecord::StreamyResultSet.new(40, 10) do |offset, limit|
      ::Killbill::Test::TestPaymentMethod.where('kb_payment_method_id is not NULL')
                                         .order('id ASC')
                                         .offset(offset)
                                         .limit(limit)
    end

    i = 0
    enum.each do |results|
      if i < 3
        results.size.should == 10
      elsif i == 3
        results.size.should == 5
      else
        fail 'Too many results'
      end
      i += 1
    end
  end
end
