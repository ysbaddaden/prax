require "logger"
require "socket"
require "net/http"
require "rack"
require "rack/builder"
require "rack/utils"

class Racker
  attr_accessor :server, :app, :options

  def self.run(*args)
    new(*args).run
  end

  def self.logger
    @logger ||= Logger.new(STDOUT)
  end
  def logger; self.class.logger; end

  def initialize(config_path, server, pid_path)
    begin
      @pid_path = pid_path
      File.open(pid_path, "w") { |f| f.write(Process.pid) }

      logger.info("Starting server on #{server}")
      if server =~ %r{^/}
        @socket_path = server
        self.server = UNIXServer.new(server)
      else
        host, port = server.split(':', 2)
        self.server = TCPServer.new(host, port || 9292)
      end

      logger.debug("Building Rack app at #{config_path}")
      self.app, self.options = Rack::Builder.parse_file(config_path)
    rescue => e
      finalize
      raise e
    end
  end

  def finalize
    File.unlink(@pid_path) if File.exists?(@pid_path)
    server.close if server
    File.unlink(@socket_path) if File.exists?(@socket_path)
  end

  def run
    Signal.trap("INT")  { exit }
    Signal.trap("TERM") { exit }
    Signal.trap("QUIT") { exit }
    Signal.trap("EXIT") { finalize }

    logger.debug("Server ready to receive connections")
    loop do
      socket = server.accept

      env = parse_env_from_socket(socket)
      code, headers, body = app.call(env)
      logger.info("#{env['REQUEST_URI']} #{code}")

      socket.write("#{env["HTTP_VERSION"]} #{code} #{http_status(code)}\r\n")
      headers["Connection"] = "close"
      headers.each { |key, value| socket.write("#{key}: #{value}\r\n") }
      socket.write("\r\n")

      body.each { |b| socket.write(b) }
      body.close if body.respond_to?(:close)  # required to prevent deadlocks in Rack::Lock
 
      socket.flush
      socket.close
    end
  end

  def parse_env_from_socket(socket)
    env = {
      "rack.version"      => [ 1, 1 ],
      "rack.multithread"  => true,
      "rack.multiprocess" => false,
      "rack.run_once"     => false,
      "SERVER_SOFTWARE"   => "racker 0.0.1",
    }
    env["rack.errors"] = STDERR
    env["rack.logger"] = logger

    _, port, host = socket.peeraddr
    env["REMOTE_ADDR"] = host

    line = socket.gets
    line.strip =~ %r{^([A-Z]+) (.*) (HTTP/1\.\d)$}
    env["REQUEST_METHOD"]  = $1
    env["REQUEST_URI"]     = $2
    env["HTTP_VERSION"]    = $3
    env["SERVER_PROTOCOL"] = $3

    if env["REQUEST_URI"] =~ /\?/
      ary = env["REQUEST_URI"].split("?")
      env["QUERY_STRING"] = ary.pop
      env["PATH_INFO"] = env["REQUEST_PATH"] = ary.join("?")
    else
      env["QUERY_STRING"] = ""
      env["PATH_INFO"] = env["REQUEST_PATH"] = env["REQUEST_URI"]
    end
    env["SCRIPT_NAME"]  = ""

    while line = socket.gets
      if line.strip =~ /^([^:]*):\s*(.*)$/
        value, key = $2, $1.upcase.gsub("-", "_")
        case key
        when "CONTENT_TYPE"   then env["CONTENT_TYPE"]   = value
        when "CONTENT_LENGTH" then env["CONTENT_LENGTH"] = value.to_i
        else env["HTTP_#{key}"] = value
        end
      end
      break if line.strip.empty?
    end

    server_name, server_port = env["HTTP_HOST"].split(":", 2)
    env["SERVER_NAME"] = server_name
    env["SERVER_PORT"] = server_port

    env["rack.url_scheme"] = "http"
    if env["CONTENT_LENGTH"] and env["CONTENT_LENGTH"] > 0
      env["rack.input"] = Net::BufferedIO.new(socket.read(env["CONTENT_LENGTH"]))
    else
      env["rack.input"] = Net::BufferedIO.new("")
    end

    env
  end

  def http_status(code)
    Rack::Utils::HTTP_STATUS_CODES[code]
  end
end
