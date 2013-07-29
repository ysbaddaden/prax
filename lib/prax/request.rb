require 'prax/http'
require 'prax/request/host'

module Prax
  XIP_RE = /^(.*?)\.?\d+.\d+\.\d+\.\d+\.xip\.io$/

  class Request
    include HTTP
    attr_reader :socket, :method, :http_version, :uri

    def initialize(socket)
      @socket = socket
      parse_request
    end

    def parse_request
      line = socket.gets
      if line and line.strip =~ %r{^([A-Z]+) (.+) (HTTP/\d\.\d)$}
        @method, @uri, @http_version = $1, $2, $3
        parse_http_headers
      end
    end

    def proxy_to(io)
      io.write "#{method} #{uri} #{http_version}\r\n"
      proxy_headers.each { |header, value| io.write "#{header}: #{value}\r\n" }
      io.write "\r\n"
      io.write socket.read(content_length) if content_length > 0
      io.flush
    end

    def proxy_headers
      self.headers.dup.merge(
        'Connection' => 'close',
        'X-Forwarded-For' => socket.peeraddr[2],
        'X-Forwarded-Host' => host,
        'X-Forwarded-Proto' => ssl ? 'https' : 'http',
        'X-Forwarded-Server' => socket.addr[2]
      )
    end

    def host
      @host ||= Host.new(header('Host').split(':').first)
    end

    def xip_host
      $1 if host =~ XIP_RE
    end
  end
end
