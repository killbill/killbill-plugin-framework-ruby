require 'spec_helper'

describe ActiveMerchant::Connection do

  before :all do
    @logger       = Logger.new(STDOUT)
    @logger.level = Logger::DEBUG

    @wiredump_device = Tempfile.new('foo')
  end

  after :all do
    @wiredump_device.close
    @wiredump_device.unlink
  end

  it 'should delegate to Typhoeus' do
    response = ssl_get('https://github.com/killbill/killbill/blob/master/pom.xml')
    response.code.should == 200
    response.return_code.should == :ok
    response.body.size.should > 0

    response = ssl_get('https://github.com/killbill/killbill/blob/master/pomme.xml')
    response.code.should == 404
    response.return_code.should == :ok
    response.body.size.should > 0

    response = ssl_get('/something')
    response.return_code.should == :url_malformat
    response.body.size.should == 0
  end

  private

  def ssl_get(endpoint, headers={})
    ssl_request(:get, endpoint, nil, headers)
  end

  def ssl_request(method, endpoint, data, headers = {})
    connection                 = ::ActiveMerchant::Connection.new(endpoint)
    connection.open_timeout    = 60
    connection.read_timeout    = 60
    connection.retry_safe      = true
    connection.verify_peer     = true
    connection.logger          = @logger
    connection.tag             = self.class.name
    connection.wiredump_device = @wiredump_device
    connection.pem             = nil
    connection.pem_password    = nil

    connection.request(method, data, headers)
  end
end
