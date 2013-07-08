require 'rack/utils'
require 'racker/logger'
require 'racker/parser'

module Racker
  class Handler
    attr_accessor :app, :socket, :env, :code, :headers, :body

    def initialize(app, socket)
      @app, @socket = app, socket
      @code = @headers = @body = nil
    end

    def handle_connection
      @env = Racker::Parser.new(socket).to_env
      call
      reply
    rescue Errno::EPIPE, Errno::EIO, Errno::ECONNRESET
    ensure
      close
    end

    def call
      @code, @headers, @body = app.call(env)
    rescue => exception
      render_exception(exception)
      raise
    end

    def reply
      socket.flush
      socket.write("#{env["HTTP_VERSION"]} #{code} #{http_status(code)}\r\n")
      headers["Connection"] = "close"
      headers.each { |key, value| socket.write("#{key}: #{value}\r\n") }
      socket.write("\r\n")
      body.each { |b| socket.write(b) }
    end

    def close
      unless socket.closed?
        socket.flush
        socket.close
      end
      body.close if body.respond_to?(:close)
      env["rack.input"].close if env and env["rack.input"]
    end

    private
      def http_status(code)
        Rack::Utils::HTTP_STATUS_CODES[code]
      end

      def render_exception(exception)
        socket.flush
        socket.write([
          "#{env["HTTP_VERSION"]} 500 #{http_status(500)}",
          "Connection: close",
          "Content-Type: text/plain",
          "X-Racker-Exception: 1"
        ].join("\r\n"))
        socket.write("\r\n\r\n")
        socket.write(exception.class.name + ": " + exception.message + "\n\n")
        exception.backtrace.each { |line| socket.write(line + "\n") }
      end
  end
end
