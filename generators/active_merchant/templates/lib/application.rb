# -- encoding : utf-8 --

configure do
  # Usage: rackup -Ilib -E test
  if development? or test?
    Killbill::<%= class_name %>.initialize! unless Killbill::<%= class_name %>.initialized
  end
end

helpers do
  def plugin
    Killbill::<%= class_name %>::PrivatePaymentPlugin.instance
  end

  def required_parameter!(parameter_name, parameter_value, message='must be specified!')
    halt 400, "#{parameter_name} #{message}" if parameter_value.blank?
  end
end

after do
  # return DB connections to the Pool if required
  ActiveRecord::Base.connection.close
end

# curl -v http://127.0.0.1:9292/plugins/killbill-<%= identifier %>/1.0/pms/1
get '/plugins/killbill-<%= identifier %>/1.0/pms/:id', :provides => 'json' do
  if pm = Killbill::<%= class_name %>::<%= class_name %>PaymentMethod.find_by_id(params[:id].to_i)
    pm.to_json
  else
    status 404
  end
end

# curl -v http://127.0.0.1:9292/plugins/killbill-<%= identifier %>/1.0/transactions/1
get '/plugins/killbill-<%= identifier %>/1.0/transactions/:id', :provides => 'json' do
  if transaction = Killbill::<%= class_name %>::<%= class_name %>Transaction.find_by_id(params[:id].to_i)
    transaction.to_json
  else
    status 404
  end
end
