require 'spec_helper'

class TestGatewayNotification
  include org.killbill.billing.payment.plugin.api.GatewayNotification

  def initialize(headers)
    @headers = headers
  end

  java_signature 'java.util.UUID getKbPaymentId'
  def kb_payment_id
  end

  java_signature 'int getStatus'
  def status
  end

  java_signature 'java.lang.String getEntity'
  def entity
  end

  java_signature 'java.util.Map<java.lang.String, java.util.List<java.lang.String>> getHeaders'
  def headers
    @headers
  end

  java_signature 'java.util.List<org.killbill.billing.payment.api.PluginProperty> getProperties'
  def properties
  end
end

describe Killbill::Plugin do

  it 'should be able to handle generic Maps' do
    # jmap is a Map<String, String>
    jmap = java.util.HashMap.new
    jlistA = java.util.LinkedList.new
    jlistA.add('Microsoft-IIS/8.0')
    jmap.put('Server', jlistA)
    jlistB = java.util.LinkedList.new
    jlistB.add('no-cache')
    jlistB.add('no-store')
    jmap.put('Cache-Control', jlistB)

    jgw_notification = TestGatewayNotification.new(jmap)
    check_notification(jgw_notification)

    rgw_notification = Killbill::Plugin::Model::GatewayNotification.new
    rgw_notification.to_ruby(jgw_notification)
    check_notification(rgw_notification)

    jgw_notification2 = rgw_notification.to_java
    check_notification(jgw_notification2)
  end

  it 'should be able to handle UTC as the fixed offset timezone' do
    jaccount = ::Killbill::Plugin::Model::Account.new
    jaccount.id = java.util.UUID.fromString('cf5a597a-cf15-45d3-8f02-95371be7f927')
    jaccount.time_zone = org.joda.time.DateTimeZone.forID('Etc/UTC')
    jaccount.reference_time = org.joda.time.DateTime.new('2015-09-01T08:01:01.000Z')
    jaccount.fixed_offset_time_zone = org.killbill.billing.util.account.AccountDateTimeUtils.getFixedOffsetTimeZone(jaccount)

    raccount = Killbill::Plugin::Model::Account.new.to_ruby(jaccount)
    raccount.id.should == 'cf5a597a-cf15-45d3-8f02-95371be7f927'
    raccount.time_zone.should be_an_instance_of TZInfo::DataTimezone
    raccount.time_zone.to_s.should == 'Etc - UTC'
    raccount.reference_time.should == '2015-09-01T08:01:01.000Z'
    raccount.fixed_offset_time_zone.should be_an_instance_of TZInfo::DataTimezone
    raccount.fixed_offset_time_zone.to_s.should == 'UTC'

    jaccount2 = raccount.to_java
    jaccount2.id.should == jaccount.id
    jaccount2.time_zone.should == jaccount.time_zone
    jaccount2.reference_time.to_s.should == '2015-09-01T08:01:01.000Z'
    jaccount2.fixed_offset_time_zone.should == jaccount.fixed_offset_time_zone
  end

  it 'should be able to handle a non-UTC fixed offset timezone' do
    jaccount = ::Killbill::Plugin::Model::Account.new
    jaccount.id = java.util.UUID.fromString('cf5a597a-cf15-45d3-8f02-95371be7f927')
    # Alaska Standard Time
    jaccount.time_zone = org.joda.time.DateTimeZone.forID('America/Juneau')
    # Time zone is AKDT (UTC-8h) between March and November
    jaccount.reference_time = org.joda.time.DateTime.new('2015-09-01T08:01:01.000Z')
    jaccount.fixed_offset_time_zone = org.killbill.billing.util.account.AccountDateTimeUtils.getFixedOffsetTimeZone(jaccount)

    raccount = Killbill::Plugin::Model::Account.new.to_ruby(jaccount)
    raccount.id.should == 'cf5a597a-cf15-45d3-8f02-95371be7f927'
    raccount.time_zone.should be_an_instance_of TZInfo::DataTimezone
    raccount.time_zone.to_s.should == 'America - Juneau'
    raccount.reference_time.should == '2015-09-01T08:01:01.000Z'
    raccount.fixed_offset_time_zone.should == '-08:00'

    jaccount2 = raccount.to_java
    jaccount2.id.should == jaccount.id
    jaccount2.time_zone.should == jaccount.time_zone
    jaccount2.reference_time.to_s.should == '2015-09-01T08:01:01.000Z'
    jaccount2.fixed_offset_time_zone.should == jaccount.fixed_offset_time_zone
  end

  private

  def check_notification(notification)
    notification.headers.size.should == 2
    notification.headers['Server'].size.should == 1
    notification.headers['Server'][0].should == 'Microsoft-IIS/8.0'
    notification.headers['Cache-Control'].size.should == 2
    notification.headers['Cache-Control'][0].should == 'no-cache'
    notification.headers['Cache-Control'][1].should == 'no-store'
  end
end
