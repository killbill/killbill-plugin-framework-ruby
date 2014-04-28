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
