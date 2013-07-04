require "socket"
require "openssl"
require "prax/config"
require "prax/logger"
require "prax/spawner"
require "prax/handler"

ROOT = File.expand_path("../../..", File.realpath(__FILE__))

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

    attr_reader :servers, :threads, :queue

    def self.run
      new.run
    end

    def initialize
      @servers = []
      @queue = Queue.new
      spawn_servers
      spawn_thread_workers
    end

    def spawn_servers
      Prax.logger.debug("Starting HTTP server on port #{Config.http_port}")
      @servers << TCPServer.new(Config.http_port)
      spawn_ssl_server if ssl_configured?
      @servers.each { |server| Prax.logger.debug(server.addr.inspect) }
    end

    def spawn_ssl_server
      Prax.logger.debug("Starting HTTPS server on port #{Config.https_port}")
      ctx      = OpenSSL::SSL::SSLContext.new
      ctx.cert = OpenSSL::X509::Certificate.new(File.read(ssl_crt))
      ctx.key  = OpenSSL::PKey::RSA.new(File.read(ssl_key))
      @servers << OpenSSL::SSL::SSLServer.new(TCPServer.new(Config.https_port), ctx)
    end

    def spawn_thread_workers
      @threads = Config.threads_count.times.map do |i|
        Thread.new do
          loop do
            socket, ssl = queue.pop
            #inet, port, host = socket.peeraddr
            #Prax.logger.debug("Thread ##{i} received request from #{host}:#{port} (#{inet}).")
            handle_connection(socket, ssl)
            #Prax.logger.debug("Thread ##{i} finished request from #{host}:#{port} (#{inet}).")
          end
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
      @servers.each { |server| server.close if server }
      Process.kill 'INT', -Process.getpgrp # Kill all children
      Prax.logger.info("Server shutdown.")
    end

    def run
      Signal.trap("INT")  { exit }
      Signal.trap("TERM") { exit }
      Signal.trap("QUIT") { exit }
      Signal.trap("EXIT") { finalize }

      Prax.logger.info("HTTP server ready on port #{Config.http_port}")
      if @servers.size == 2
        Prax.logger.info("HTTPS server ready on port #{Config.https_port}")
      end

      loop do
        begin
          IO.select(@servers).first.each do |server|
            ssl = server.is_a?(OpenSSL::SSL::SSLServer)
            queue << [server.accept, ssl]
          end
        rescue OpenSSL::SSL::SSLError
        end
      end
    end
  end
end
