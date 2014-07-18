require 'bundler'
Bundler.require(:default)

get '/' do
  Sinatra::VERSION
end

run Sinatra::Application
