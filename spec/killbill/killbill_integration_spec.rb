require 'spec_helper'

java_import java.util.UUID
java_import org.joda.time.DateTimeZone
java_import org.killbill.billing.catalog.api.Currency

describe Killbill::Plugin do
  before(:each) do
    @account_user_api = MockAccountUserApi.new
  end

  it 'should be able to access Killbill mock APIs' do
    @account_user_api.createAccountFromParams(UUID.randomUUID,
                                    'externalKey',
                                    'email',
                                    'name',
                                    1,
                                    Currency::USD,
                                    12,
                                    UUID.randomUUID,
                                    DateTimeZone::UTC,
                                    'locale',
                                    'address1',
                                    'address2',
                                    'companyName',
                                    'city',
                                    'stateOrProvince',
                                    'country',
                                    'postalCode',
                                    'phone',
                                    'notes')
    account = @account_user_api.getAccountByKey('externalKey', nil)
    account.external_key.should == 'externalKey'
    account.email.should == 'email'
    account.name.should == 'name'
    account.first_name_length.should == 1
    account.currency.should == Currency::USD
    account.payment_method_id.should_not be_nil
    account.time_zone.should == DateTimeZone::UTC
    account.locale.should == 'locale'
    account.address1.should == 'address1'
    account.address2.should == 'address2'
    account.company_name.should == 'companyName'
    account.city.should == 'city'
    account.state_or_province.should == 'stateOrProvince'
    account.country.should == 'country'
    account.postal_code.should == 'postalCode'
    account.phone.should == 'phone'
    account.notes.should == 'notes'
  end
end

