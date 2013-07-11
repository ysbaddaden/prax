require "socket"
require "openssl"
require "prax/config"
require "prax/logger"
require "prax/workers"
require "prax/spawner"
require "prax/handler"

ROOT = File.expand_path("../../..", File.realpath(__FILE__))
Thread.abort_on_exception = Prax::Config.debug?

module Prax
  module SSL
    def ssl_crt; File.join(ROOT, "ssl", "server.crt"); end
    def ssl_key; File.join(ROOT, "ssl", "server.key"); end

    def ssl_configured?
      File.exists?(ssl_crt) and File.exists?(ssl_key)
    end
  end

  class Server
    include SSL

    attr_reader :queue, :servers, :workers

    def self.run
      new.run
    end

    def initialize
      @servers = []
      @queue = Queue.new
      trap_signals
      spawn_servers
      spawn_workers
    end

    def spawn_servers
      Prax.logger.debug("Starting HTTP server on port #{Config.http_port}")

      servers << TCPServer.new(Config.http_port)
      Prax.logger.info("HTTP server ready on port #{Config.http_port}")

      spawn_ssl_server if ssl_configured?
      Prax.logger.info("HTTPS server ready on port #{Config.https_port}")

      #servers.each { |server| Prax.logger.debug(server.addr.inspect) }
    end

    def spawn_ssl_server
      Prax.logger.debug("Starting HTTPS server on port #{Config.https_port}")
      ctx      = OpenSSL::SSL::SSLContext.new
      ctx.cert = OpenSSL::X509::Certificate.new(File.read(ssl_crt))
      ctx.key  = OpenSSL::PKey::RSA.new(File.read(ssl_key))
      servers << OpenSSL::SSL::SSLServer.new(TCPServer.new(Config.https_port), ctx)
    end

    def spawn_workers
      @workers = Prax::Workers.new(Config.threads_count) do
        loop do
          socket, ssl = queue.pop
          handle_connection(socket, ssl)
        end
      end
    end

    def handle_connection(socket, ssl = nil)
      #inet, port, host = socket.peeraddr
      #Prax.logger.debug("New connection from #{host}:#{port} (#{inet}).")
      Handler.new(socket, ssl).run
      socket.close
      #Prax.logger.debug("Closed connection from #{host}:#{port} (#{inet}).")
    end

    def finalize
      workers.exiting = true
      servers.each { |server| server.close if server }
      Process.kill 'INT', -Process.getpgrp # Kill all children
      Prax.logger.info("Server shutdown.")
    end

    def run
      loop do
        begin
          IO.select(servers).first.each do |server|
            ssl = server.is_a?(OpenSSL::SSL::SSLServer)
            queue << [server.accept, ssl]
          end
        rescue OpenSSL::SSL::SSLError
        end
      end
    end

    private
      def trap_signals
        Signal.trap("INT")  { exit }
        Signal.trap("TERM") { exit }
        Signal.trap("QUIT") { exit }
        Signal.trap("EXIT") { finalize }
      end
  end
end
