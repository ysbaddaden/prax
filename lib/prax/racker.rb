require "logger"
require "socket"
require "stringio"
require "tempfile"
require "rack"
require "rack/builder"
require "rack/utils"

class Racker
  attr_accessor :server, :app, :options

  def self.run(*args)
    new(*args).run
  end

  def self.logger
    @logger ||= begin
      logger = Logger.new(STDOUT)
      logger.level = Logger::INFO unless ENV["PRAX_DEBUG"]
      logger
    end
  end
  def logger; self.class.logger; end

  def initialize(options = {})
    Signal.trap("INT")  { exit }
    Signal.trap("TERM") { exit }
    Signal.trap("QUIT") { exit }
    Signal.trap("EXIT") { finalize }

    server, @pid_path = options[:server], options[:pid]
    config_path = Dir.getwd + "/config.ru"

    File.open(@pid_path, "w") { |f| f.write(Process.pid) }

    logger.debug("Starting server on #{server}")
    if server =~ %r{^/}
      @socket_path = server
      self.server = UNIXServer.new(server)
    else
      host, port = server.split(':', 2)
      self.server = TCPServer.new(host, port || 9292)
    end

    logger.debug("Building Rack app at #{config_path}")
    self.app, self.options = Rack::Builder.parse_file(config_path)
  rescue
    finalize
    raise
  end

  def finalize
    server.close if server
    File.unlink(@pid_path) if File.exists?(@pid_path)
    File.unlink(@socket_path) if @socket_path and File.exists?(@socket_path)
  end

  def run
    logger.info("Server ready to receive connections")
    loop do
#      Thread.start(server.accept) { |socket| handle_connection(socket) }
      handle_connection(server.accept)
    end
  end

  def handle_connection(socket)
    env = parse_env_from_socket(socket)

    code, headers, body = app.call(env)
    logger.info("#{code} - #{env['REQUEST_URI']}")

    socket.flush
    socket.write("#{env["HTTP_VERSION"]} #{code} #{http_status(code)}\r\n")
    headers["Connection"] = "close"
    headers.each { |key, value| socket.write("#{key}: #{value}\r\n") }
    socket.write("\r\n")

    body.each { |b| socket.write(b) }
    body.close if body.respond_to?(:close)

    socket.flush
    socket.close
  ensure
    env["rack.input"].close if env and env["rack.input"]
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
    env["rack.input"] = read_body_as_rewindable_input(socket, env["CONTENT_LENGTH"] || 0)

    env
  end

  def read_body_as_rewindable_input(socket, content_length)
    if content_length > (1024 * (80 + 32))
      tempfile = Tempfile.new("RackerInputBody")
      tempfile.chmod(000)
      tempfile.set_encoding("ASCII-8BIT") if tempfile.respond_to?(:set_encoding)
      tempfile.binmode
      ::File.unlink(tempfile.path)
#      IO.copy_stream(socket, tempfile, content_length)
      tempfile.write(socket.read(content_length))
      tempfile.rewind
      tempfile
    elsif content_length > 0
      StringIO.new(socket.read(content_length))
    else
      StringIO.new("")
    end
  end

  def http_status(code)
    Rack::Utils::HTTP_STATUS_CODES[code]
  end
end
