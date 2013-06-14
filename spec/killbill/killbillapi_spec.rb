require 'spec_helper'
require 'date'
require 'killbill/killbill_api'

require 'killbill/gen/account_data'



describe Killbill::Plugin do

  before(:each) do
    @account_user_api_mock = MockAccountUserApi.new
    @kb_apis = Killbill::Plugin::KillbillApi.new("foo", {:account_user_api => @account_user_api_mock})
    @account = Killbill::Plugin::Model::AccountData.new
    @account.external_key="external_key"
    @account.name="name"
    @account.first_name_length=3
    @account.email="email"
    @account.bill_cycle_day_local=1
    @account.currency=:USD
    @account.locale="locale"
    @account.address1="address1"
    @account.time_zone=:UTC
    @account.city="San Francisco"

    #:tenant_id, :user_token, :user_name, :call_origin, :user_type, :reason_code, :comments, :created_date, :updated_date
    @context = Killbill::Plugin::Model::CallContext.new
    @context.tenant_id=nil
    @context.user_token="15350dd4-3742-485d-a9c3-584e491ea38b"
    @context.user_name="foo"
    @context.call_origin=:EXTERNAL
    @context.user_type=:SYSTEM
    @context.reason_code="whatever"
    @context.comments="yo"
    @context.created_date=DateTime.new
    @context.updated_date=DateTime.new
  end

  it 'should test create/get_account_by_id' do

    puts "should test create/get_account_by_id START"

    account_user_api = @kb_apis.account_user_api

    account_created = account_user_api.create_account(@account, @context)

    puts "account created"

    account_created.should be_an_instance_of Killbill::Plugin::Model::Account

    account_fetched = account_user_api.get_account_by_id(account_created.id, @context)
    account_fetched.should be_an_instance_of Killbill::Plugin::Model::Account
    account_fetched.id.should be_an_instance_of String
    account_fetched.id.should == account_created.id
    account_fetched.external_key.should == "external_key"
    account_fetched.name.should == "name"
    account_fetched.first_name_length.should == 3
    account_fetched.email.should == "email"
    account_fetched.bill_cycle_day_local.should == 1
    account_fetched.currency.should == :USD
    account_fetched.locale.should == "locale"
    account_fetched.address1.should == "address1"
    account_fetched.address2.should == nil
    #account_fetched.time_zone.should be_an_instance_of TZInfo::Timezone (seemes to return TZInfo::LinkedTimezone instead)
    account_fetched.time_zone.to_s.should == :UTC.to_s
  end

end
