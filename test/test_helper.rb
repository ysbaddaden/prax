ENV['PRAX_HOST_ROOT'] = File.expand_path('../hosts', __FILE__)
ENV['PRAX_HTTP_PORT'] = '20557'
ENV['PRAX_HTTPS_PORT'] = '20556'

require 'bundler'
Bundler.require(:test)

require 'timeout'
require 'socket'

$:.unshift File.expand_path("../../lib", File.realpath(__FILE__))
Thread.abort_on_exception = true

class Minitest::Spec
  let(:prax_env) do
    {
      'PRAX_HOST_ROOT' => File.expand_path('../hosts', __FILE__),
      'PRAX_DEBUG' => "1",
    }
  end

  let(:prax_cmd) do
    "#{File.expand_path('../../bin/prax', __FILE__)} start --foreground"
  end

  before do
    _, out, err, @thr = Open3.popen3(prax_env, prax_cmd)
    while line = out.gets
      break if line =~ /Prax is ready/
    end

    Thread.new do
      while line = out.gets
        #puts line
      end
    end

    Thread.new do
      while line = err.gets
        #puts line
      end
    end
  end

  after do
    begin
      Process.kill('TERM', @thr[:pid])
      sleep 0.1
      Process.kill('KILL', @thr[:pid])
    rescue Errno::ESRCH
    end
  end

  #def client(type, hostname, port = nil, &block)
  #  case type
  #  when :tcp  then tcp_client(hostname,  port, &block)
  #  when :ssl  then ssl_client(hostname,  port, &block)
  #  when :unix then unix_client(hostname, &block)
  #  end
  #end

  #def tcp_client(hostname, port)
  #  socket = TCPSocket.new(hostname, port)
  #  yield socket if block_given?
  #ensure
  #  socket.close if socket
  #end

  #def unix_client(path)
  #  socket = UNIXSocket.new(path)
  #  yield socket if block_given?
  #ensure
  #  socket.close if socket
  #end

  #def ssl_client(hostname, port)
  #  tcp_client(hostname, port) do |tcp|
  #    socket = OpenSSL::SSL::SSLSocket.new(tcp, ssl_context)
  #    socket.sync_close = true
  #    socket.connect
  #    yield socket if block_given?
  #  end
  #end

  #def ssl_context
  #  @ssl_context ||= begin
  #    ctx      = OpenSSL::SSL::SSLContext.new
  #    path     = File.expand_path('../ssl', __FILE__)
  #    ctx.cert = OpenSSL::X509::Certificate.new(File.read(File.join(path, 'client.crt')))
  #    ctx.key  = OpenSSL::PKey::RSA.new(File.read(File.join(path, 'client.key')))
  #    ctx
  #  end
  #end
end
