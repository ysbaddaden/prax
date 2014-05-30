require 'prax/http'

module Prax
  class Response
    include HTTP
    include Timeout

    attr_reader :socket

    def initialize(socket)
      @socket = socket
      parse_response
    end

    def parse_response
      timeout(60) { parse_http_headers if @status_line = socket.gets }
    rescue
      # NOTE: it may fail because the port-forwarded app isn't reachable
      raise CantStartApp.new
    end

    def proxy_to(io)
      io.write @status_line
      headers.each { |header, value| io.write "#{header}: #{value}\r\n" }
      io.write "\r\n"
      IO.copy_stream socket, io #, header?('Content-Length') ? content_length : nil
      io.flush
    rescue Errno::EPIPE, Errno::ECONNRESET
    end
  end
end
