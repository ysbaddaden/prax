require 'prax/http'

module Prax
  class Response
    include HTTP
    attr_reader :socket

    def initialize(socket)
      @socket = socket
      parse_response
    end

    def parse_response
      parse_http_headers if @status_line = socket.gets
    end

    def proxy_to(io)
      io.write "#{@status_line}\r\n"
      headers.each { |header, value| io.write "#{header}: #{value}\r\n" }
      io.write "\r\n"

      if content_length > 0
        io.write socket.read(content_length)
      elsif header('Connection') == 'close'
        IO.copy_stream socket, io
      end

      io.flush
    rescue Errno::EPIPE, Errno::ECONNRESET
    end
  end
end
