require "socket"
require "logger"
require File.expand_path("../config",  __FILE__)
require File.expand_path("../spawner", __FILE__)
require File.expand_path("../handler", __FILE__)

ROOT = File.expand_path("../..", __FILE__)

module Row
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  class Server
    attr_reader :server

    def self.run
      new.run
    end

    def initialize
      @server = TCPServer.new(Config.http_host, Config.http_port)
      Row.logger.debug("Started server on #{Config.http_host}:#{Config.http_port}")
    end

    def finalize
      @server.close if @server
      Row.logger.debug("Terminated server.")
    end

    def run
      Signal.trap("INT")  { exit }
      Signal.trap("TERM") { exit }
      Signal.trap("QUIT") { exit }
      Signal.trap("EXIT") { finalize }

      Row.logger.debug("Server is now accepting connections.")

      loop do
        socket = server.accept

        _, port, host = socket.peeraddr
        Row.logger.debug("New connection from #{host}:#{port} (#{_}).")

        Handler.new(socket).run
        socket.close

        Row.logger.debug("Closed connection from #{host}:#{port} (#{_}).")

#        Thread.start(server.accept) do |socket|
#          Handler.new(socket).run
#          socket.close
#        end
      end
    end
  end
end
