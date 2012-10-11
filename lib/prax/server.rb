require 'socket'

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
    attr_reader :servers

    class << self
      def run
        new.run
      end
    end

    def initialize
      Prax.logger.debug("Starting HTTP server on port #{Config.http_port}")
      @servers = []
      @servers << TCPServer.new(Config.http_port)
      Prax.logger.debug(@servers.first.addr.inspect)

      if ssl_configured?
        Prax.logger.debug("Starting HTTPS server on port #{Config.https_port}")
        ctx      = OpenSSL::SSL::SSLContext.new
        ctx.cert = OpenSSL::X509::Certificate.new(File.open(ssl_crt))
        ctx.key  = OpenSSL::PKey::RSA.new(File.open(ssl_key))
        @servers << OpenSSL::SSL::SSLServer.new(
          TCPServer.new(Config.https_port),
          ctx
        )
        Prax.logger.debug(@servers.last.addr.inspect)
      end
    end

    def finalize
      @servers.each { |server| server.close if server }
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
            if Config.thread?
              Thread.start(server.accept) do |socket|
                handle_connection(socket, server.is_a?(OpenSSL::SSL::SSLServer))
              end
            else
              handle_connection(server.accept)
            end
          end
        rescue OpenSSL::SSL::SSLError
        end
      end
    end

    def handle_connection(socket, ssl = nil)
      _, port, host = socket.peeraddr
      Prax.logger.debug("New connection from #{host}:#{port} (#{_}).")
      Handler.new(socket, ssl).run
      socket.close
      Prax.logger.debug("Closed connection from #{host}:#{port} (#{_}).")
    end
  end
end
