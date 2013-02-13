require 'sinatra'

get "/ping" do
  return 'pong'
end

run Sinatra::Application
