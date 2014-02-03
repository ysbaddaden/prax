require 'test_helper'
require 'open3'
require 'net/http'

describe "FQDN" do
  it "must access applications" do
    assert_equal "example", Net::HTTP.get(URI('http://example.dev:20557/'))
    assert_equal "example", Net::HTTP.get(URI('http://www.example.dev:20557/'))

    assert_equal "app1.example", Net::HTTP.get(URI('http://app1.example.dev:20557/'))
    assert_equal "app1.example", Net::HTTP.get(URI('http://www.app1.example.dev:20557/'))

    assert_equal "app2.example", Net::HTTP.get(URI('http://app2.example.dev:20557/'))
    assert_equal "app2.example", Net::HTTP.get(URI('http://w3.app2.example.dev:20557/'))
  end
end
