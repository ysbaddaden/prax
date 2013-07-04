require "stringio"
require "tempfile"
require 'racker/logger'

module Racker
  class Parser
    attr_accessor :socket

    def initialize(socket)
      @socket = socket
    end

    def to_env
      default_env
      parse_remote_addr
      parse_request_line
      parse_query_string
      parse_headers
      parse_host
      @env["rack.input"] = read_body_as_rewindable_input(socket, @env["CONTENT_LENGTH"] || 0)
      @env
    end

    private
      def default_env
        @env = {
          "rack.version"      => [1, 1],
          "rack.multithread"  => true,
          "rack.multiprocess" => false,
          "rack.run_once"     => false,
          "SERVER_SOFTWARE"   => "racker 0.0.1",
        }
        @env["rack.errors"] = STDERR
        @env["rack.logger"] = Racker.logger
        @env["rack.url_scheme"] = "http"
      end

      def parse_remote_addr
        _, _, host = socket.peeraddr
        @env["REMOTE_ADDR"] = host
      end

      def parse_request_line
        line = socket.gets
        line.strip =~ %r{^([A-Z]+) (.*) (HTTP/1\.\d)$}
        @env["REQUEST_METHOD"]  = $1
        @env["REQUEST_URI"]     = $2
        @env["HTTP_VERSION"]    = $3
        @env["SERVER_PROTOCOL"] = $3
      end

      def parse_query_string
        idx = @env["REQUEST_URI"].rindex('?')
        if idx
          @env["PATH_INFO"] = @env["REQUEST_PATH"] = @env["REQUEST_URI"][0...idx]
          @env["QUERY_STRING"] = @env["REQUEST_URI"][(idx + 1)..-1]
        else
          @env["PATH_INFO"] = @env["REQUEST_PATH"] = @env["REQUEST_URI"]
          @env["QUERY_STRING"] = ""
        end
        @env["SCRIPT_NAME"] = ""
      end

      def parse_headers
        while line = socket.gets
          if line.strip =~ /^([^:]*):\s*(.*)$/
            value, key = $2, $1.upcase.gsub("-", "_")
            case key
            when "CONTENT_TYPE"   then @env["CONTENT_TYPE"]   = value
            when "CONTENT_LENGTH" then @env["CONTENT_LENGTH"] = value.to_i
            else @env["HTTP_#{key}"] = value
            end
          end
          break if line.strip.empty?
        end
      end

      def parse_host
        server_name, server_port = @env["HTTP_HOST"].split(":", 2)
        @env["SERVER_NAME"] = server_name
        @env["SERVER_PORT"] = server_port
      end

      def read_body_as_rewindable_input(socket, content_length)
        if content_length > (1024 * (80 + 32))
          tempfile = Tempfile.new("RackerInputBody")
          tempfile.chmod(000)
          tempfile.set_encoding("ASCII-8BIT") if tempfile.respond_to?(:set_encoding)
          tempfile.binmode
          ::File.unlink(tempfile.path)
          #IO.copy_stream(socket, tempfile, content_length)
          tempfile.write(socket.read(content_length))
          tempfile.rewind
          tempfile
        elsif content_length > 0
          StringIO.new(socket.read(content_length))
        else
          StringIO.new("")
        end
      end
  end
end
