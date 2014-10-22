# -- encoding : utf-8 --

set :views, File.expand_path(File.dirname(__FILE__) + '/views')

include Killbill::Plugin::ActiveMerchant::Sinatra

configure do
  # Usage: rackup -Ilib -E test
  if development? or test?
    # Make sure the plugin is initialized
    plugin              = ::Killbill::<%= class_name %>::PaymentPlugin.new
    plugin.logger       = Logger.new(STDOUT)
    plugin.logger.level = Logger::INFO
    plugin.conf_dir     = File.dirname(File.dirname(__FILE__)) + '/..'
    plugin.start_plugin
  end
end

helpers do
  def plugin(session = {})
    ::Killbill::<%= class_name %>::PrivatePaymentPlugin.new(session)
  end
end

# curl -v http://127.0.0.1:9292/plugins/killbill-<%= identifier %>/form
get '/plugins/killbill-<%= identifier %>/form', :provides => 'html' do
  order_id   = request.GET['order_id']
  account_id = request.GET['account_id']
  options    = {
      :amount           => request.GET['amount'],
      :currency         => request.GET['currency'],
      :test             => request.GET['test'],
      :credential2      => request.GET['credential2'],
      :credential3      => request.GET['credential3'],
      :credential4      => request.GET['credential4'],
      :country          => request.GET['country'],
      :account_name     => request.GET['account_name'],
      :transaction_type => request.GET['transaction_type'],
      :authcode         => request.GET['authcode'],
      :notify_url       => request.GET['notify_url'],
      :return_url       => request.GET['return_url'],
      :redirect_param   => request.GET['redirect_param'],
      :forward_url      => request.GET['forward_url']
  }

  @form = plugin(session).payment_form_for(order_id, account_id, :<%= identifier %>, options) do |service|
    # Add your custom hidden tags here, e.g.
    #service.token = config[:<%= identifier %>][:token]
    submit_tag 'Submit'
  end

  erb :form
end

# curl -v http://127.0.0.1:9292/plugins/killbill-<%= identifier %>/1.0/pms/1
get '/plugins/killbill-<%= identifier %>/1.0/pms/:id', :provides => 'json' do
  if pm = ::Killbill::<%= class_name %>::<%= class_name %>PaymentMethod.find_by_id(params[:id].to_i)
    pm.to_json
  else
    status 404
  end
end

# curl -v http://127.0.0.1:9292/plugins/killbill-<%= identifier %>/1.0/transactions/1
get '/plugins/killbill-<%= identifier %>/1.0/transactions/:id', :provides => 'json' do
  if transaction = ::Killbill::<%= class_name %>::<%= class_name %>Transaction.find_by_id(params[:id].to_i)
    transaction.to_json
  else
    status 404
  end
end

# curl -v http://127.0.0.1:9292/plugins/killbill-<%= identifier %>/1.0/responses/1
get '/plugins/killbill-<%= identifier %>/1.0/responses/:id', :provides => 'json' do
  if transaction = ::Killbill::<%= class_name %>::<%= class_name %>Response.find_by_id(params[:id].to_i)
    transaction.to_json
  else
    status 404
  end
end
