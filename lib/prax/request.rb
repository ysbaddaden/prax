require 'tempfile'
require 'prax/http'
require 'prax/request/host'

module Prax
  XIP_RE = /^(.*?)\.?\d+.\d+\.\d+\.\d+\.xip\.io$/

  class Request
    include HTTP
    attr_reader :socket, :ssl, :method, :http_version, :uri

    def initialize(socket, ssl = nil)
      @socket, @ssl = socket, ssl
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
      IO.copy_stream(socket, io, content_length)
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

    def query_string
      parse_query_string unless @query_string
      @query_string
    end

    def path_info
      parse_query_string unless @path_info
      @path_info
    end

    def body_as_rewindable_input
      if content_length > (1024 * (80 + 32))
        body_as_tempfile
      elsif content_length > 0
        StringIO.new(socket.read(content_length))
      else
        StringIO.new('')
      end
    end

    def host
      @host ||= Host.new(header('Host').split(':').first)
    end

    def port
      @port ||= begin
        host = header('Host')
        host.include?(':') ? host.split(':').last.to_i : (ssl ? 443 : 80)
      end
    end

    def xip_host
      $1 if host =~ XIP_RE
    end

    def remote_addr
      socket.is_a?(::UNIXSocket) ? '127.0.0.1' : socket.peeraddr[2]
    end

    private
      def parse_query_string
        if idx = uri.rindex('?')
          @path_info = uri[0...idx]
          @query_string = uri[(idx + 1)..-1]
        else
          @path_info = uri
          @query_string = ''
        end
      end

      def body_as_tempfile
        tempfile = Tempfile.new('RackerInputBody')
        tempfile.chmod(000)
        tempfile.set_encoding('ASCII-8BIT') if tempfile.respond_to?(:set_encoding)
        tempfile.binmode
        File.unlink(tempfile.path)
        IO.copy_stream(socket, tempfile, content_length)
        tempfile.rewind
        tempfile
      end
  end
end
