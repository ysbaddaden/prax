#require 'test_helper'
#require 'prax/microserver'
#
#class TestMicroServer < Prax::MicroServer
#  def initialize
#    @ssl_crt = File.expand_path('../ssl/server.crt', __FILE__)
#    @ssl_key = File.expand_path('../ssl/server.key', __FILE__)
#    super
#  end
#
#  def serve(socket, ssl)
#    socket.write("OK")
#    socket.close
#  end
#end
#
#describe "MicroServer" do
#  let :server do
#    TestMicroServer.new
#  end
#
#  let :socket_path do
#    '/tmp/prax_test.sock'
#  end
#
#  after do
#    server.stop(true) if server.started?
#
#    if File.exists?(socket_path)
#      File.unlink(socket_path)
#      puts "Warning: #{socket_path} wasn't cleaned. Cleaning now."
#    end
#  end
#
#  describe "add_tcp_listener" do
#    before { server.add_tcp_listener(20569) }
#
#    it "must add" do
#      assert_equal 1, server.listeners.size
#      assert_instance_of TCPServer, server.listeners.first
#    end
#
#    it "must listen" do
#      server.run
#      tcp_client('localhost', 20569) { |socket| assert_equal 'OK', socket.gets }
#    end
#  end
#
#  describe "add_ssl_listener" do
#    before { server.add_ssl_listener(20568) }
#
#    it "must add" do
#      assert_equal 1, server.listeners.size
#      assert_instance_of OpenSSL::SSL::SSLServer, server.listeners.first
#    end
#
#    it "must listen" do
#      server.run
#      ssl_client('localhost', 20568) { |socket| assert_equal 'OK', socket.gets }
#    end
#  end
#
#  describe "add_unix_listener" do
#    before { server.add_unix_listener(socket_path) }
#
#    it "must add" do
#      assert_equal 1, server.listeners.size
#      assert_instance_of UNIXServer, server.listeners.first
#    end
#
#    it "must listen" do
#      server.run
#      unix_client(socket_path) { |socket| assert_equal 'OK', socket.gets }
#    end
#  end
#
#  it "must add unix server" do
#    server.add_unix_listener(socket_path)
#    assert_equal 1, server.listeners.size
#    assert_instance_of UNIXServer, server.listeners.first
#
#    server.run
#    unix_client(socket_path) { |socket| assert_equal 'OK', socket.gets }
#  end
#
#  describe "many listeners" do
#    before do
#      server.add_tcp_listener(20569)
#      server.add_ssl_listener(20568)
#      server.add_unix_listener(socket_path)
#    end
#
#    it "must add the listeners" do
#      assert_equal 3, server.listeners.size
#      assert_instance_of TCPServer, server.listeners[0]
#      assert_instance_of OpenSSL::SSL::SSLServer, server.listeners[1]
#      assert_instance_of UNIXServer, server.listeners[2]
#    end
#
#    it "must serve requests" do
#      server.run
#      tcp_client('localhost', 20569) { |socket| assert_equal 'OK', socket.gets }
#      ssl_client('localhost', 20568) { |socket| assert_equal 'OK', socket.gets }
#      unix_client(socket_path) { |socket| assert_equal 'OK', socket.gets }
#    end
#  end
#
#  describe "stop" do
#    before do
#      server.add_tcp_listener(20569)
#      server.run
#      Thread.pass
#      server.stop(true)
#    end
#
#    it "must stop" do
#      refute server.started?
#    end
#
#    it "must join the thread" do
#      refute server.thread.status
#    end
#  end
#end
