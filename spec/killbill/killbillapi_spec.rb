require 'spec_helper'

require 'killbill/jkillbill_api'
require 'killbill/killbill_api'

require 'killbill/gen/account_data'
require 'killbill/gen/currency'
require 'killbill/gen/date_time_zone'



describe Killbill::Plugin do

  before(:each) do
    @account_user_api_mock = MockAccountUserApi.new
    @japi_proxy = Killbill::Plugin::JKillbillApi.new("foo", {:account_user_api => @account_user_api_mock})
    @kb_apis = Killbill::Plugin::KillbillApi.new(@japi_proxy)
    @account = Killbill::Plugin::Model::AccountData.new("external_key", "name", 3, "email", 1, Killbill::Plugin::Model::Currency::USD, nil, Killbill::Plugin::Model::DateTimeZone::UTC, "locale", "address1", nil,
"company_name", "city", "state_or_province", "postal_code", "country", "phone", true, false)
  end

  it 'should test create/get_account_by_id' do

    account_created = @kb_apis.create_account(@account)
    account_created.should be_an_instance_of Killbill::Plugin::Model::Account

    account_fetched = @kb_apis.get_account_by_id(account_created.id)
    account_fetched.should be_an_instance_of Killbill::Plugin::Model::Account
    account_fetched.id.should be_an_instance_of Killbill::Plugin::Model::UUID
    account_fetched.id.to_s.should == account_created.id.to_s
    account_fetched.external_key.should == "external_key"
    account_fetched.name.should == "name"
    account_fetched.first_name_length.should == 3
    account_fetched.email.should == "email"
    account_fetched.bill_cycle_day_local.should == 1
    account_fetched.currency.should == Killbill::Plugin::Model::Currency::USD
    account_fetched.locale.should == "locale"
    account_fetched.address1.should == "address1"
    account_fetched.address2.should == nil
    account_fetched.time_zone.should == Killbill::Plugin::Model::DateTimeZone::UTC
    account_fetched.company_name.should == "company_name"
    account_fetched.city.should == "city"
    account_fetched.state_or_province.should == "state_or_province"
    account_fetched.postal_code.should == "postal_code"
    account_fetched.country.should == "country"
    account_fetched.phone.should == "phone"
  end

end
