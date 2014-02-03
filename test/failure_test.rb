require 'test_helper'
require 'open3'
require 'net/http'

describe "crashes" do
  describe "invalid config.ru" do
    before { File.unlink log_path(:invalid) rescue nil }

    it "reports failure" do
      assert_match "Can't start application", Net::HTTP.get(URI('http://invalid.dev:20557/'))
      assert_match "crash on application boot", log(:invalid)
    end
  end

  describe "crashing request" do
    before { File.unlink log_path(:failure) rescue nil }

    it "reports failure" do
      assert_match "StandardError: crash on request", Net::HTTP.get(URI('http://failure.dev:20557/'))
      assert_match "StandardError: crash on request", log(:failure)
    end
  end

  describe "config.ru doesn't run anything" do
    before { File.unlink log_path('wont-run') rescue nil }

    it "reports failure" do
      assert_match "Can't start application", Net::HTTP.get(URI('http://wont-run.dev:20557/'))
      assert_match "missing run or map statement", log('wont-run')
    end
  end

  def log(app_name)
    File.read log_path(app_name)
  end

  def log_path(app_name)
    File.expand_path("../hosts/_logs/#{app_name}.log", __FILE__)
  end
end
