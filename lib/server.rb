require "socket"
require "logger"
require File.expand_path("../config",  __FILE__)
require File.expand_path("../spawner", __FILE__)
require File.expand_path("../handler", __FILE__)

ROOT = File.expand_path("../..", __FILE__)

module Prax
  def self.logger
    @logger ||= begin
      logger = Logger.new(STDOUT)
      logger.level = Logger::INFO unless Config.debug?
      logger
    end
  end

  class Server
    attr_reader :server

    def self.run
      new.run
    end

    def initialize
      Prax.logger.debug("Starting server on #{Config.http_host}:#{Config.http_port}")
      @server = TCPServer.new(Config.http_host, Config.http_port)
    end

    def finalize
      @server.close if @server
      Prax.logger.info("Server shutdown.")
    end

    def run
      Signal.trap("INT")  { exit }
      Signal.trap("TERM") { exit }
      Signal.trap("QUIT") { exit }
      Signal.trap("EXIT") { finalize }

      Prax.logger.info("Server ready on #{Config.http_host}:#{Config.http_port}")

      loop do
        if Config.thread?
          Thread.start(server.accept) { |socket| handle_connection(socket) }
        else
          handle_connection(server.accept)
        end
#        socket = server.accept
#        _, port, host = socket.peeraddr
#        Prax.logger.debug("New connection from #{host}:#{port} (#{_}).")
#        Handler.new(socket).run
#        socket.close
#        Prax.logger.debug("Closed connection from #{host}:#{port} (#{_}).")

#        Thread.start(server.accept) do |socket|
#          _, port, host = socket.peeraddr
#          Prax.logger.debug("New connection from #{host}:#{port} (#{_}).")
#          Handler.new(socket).run
#          socket.close
#          Prax.logger.debug("Closed connection from #{host}:#{port} (#{_}).")
#        end
      end
    end

    def handle_connection(socket)
      _, port, host = socket.peeraddr
      Prax.logger.debug("New connection from #{host}:#{port} (#{_}).")
      Handler.new(socket).run
      socket.close
      Prax.logger.debug("Closed connection from #{host}:#{port} (#{_}).")
    end
  end
end
