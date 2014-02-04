require 'rack/utils'

run(lambda do |env|
  headers = {}
  Rack::Utils.set_cookie_header!(headers, 'first',  value: '123')
  Rack::Utils.set_cookie_header!(headers, 'second', value: '456')
  [200, headers, ["OK"]]
end)
