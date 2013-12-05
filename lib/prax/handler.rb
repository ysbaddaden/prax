require "erb"
require "timeout"
require "prax/public_file"

module Prax
  class Handler
    class NoSuchApp < StandardError; end
    class CantStartApp < StandardError; end

    include Prax::ContentType
    include Prax::PublicFile

    def initialize(input, ssl = nil)
      @input = input
      @ssl = ssl
    end

    def run
      parse_request
      handle_request if @request.any?
    rescue NoMethodError => e
      Prax.logger.warn(e.message + "\n" + e.backtrace.join("\n"))
    ensure
      @output.close if @output
    end

    def handle_request
      if public_file_exists?
        stream_public_file
      else
        spawn_app
        proxy_request if @output
      end
    end

    def app_name
      @app_name ||= lambda {
        host = @request_headers["host"]

        unless Config.ip?(host)
          app_segments = if Config.xip?(host)
            Config.xip_segments(host)
          else
            parse_host(host)
          end

          app_name = Config.find_app(app_segments)
          return app_name if app_name
        end

        return :default if Config.configured_default_app?
        raise NoSuchApp.new
      }.call
    end

    def spawn_app(try = 0)
      @app = Spawner.new(app_name) or raise CantStartApp.new
      @output = @app.socket

    rescue Errno::ECONNREFUSED => e
      Prax.logger.debug("Stalled socket: #{app_name}")
      spawn_app(try += 1) unless try == 1

    rescue NoSuchApp => e
      Prax.logger.debug("No such application: #{app_name}")
      render(:no_such_app)

    rescue CantStartApp => e
      Prax.logger.debug("Can't start application: #{app_name}")
      render(:cant_start_app)
    end

    def parse_request
      @request_headers = {}
      @request = []

      line = @input.gets
#      line.force_encoding("ASCII-8BIT") if line.respond_to?(:force_encoding)

      if line and line.strip =~ %r{^([A-Z]+) (.+) (HTTP/\d\.\d)$}
        @request << line
        @http_method  = $1
        @request_uri  = $2
        @http_version = $3

        while line = @input.gets
#          line.force_encoding("ASCII-8BIT") if line.respond_to?(:force_encoding)
          @request_headers[$1.downcase] = $2 if line.strip =~ /^([^:]+):\s*(.*)$/
          @request << line
          break if line.strip.empty?
        end
      end
    end

    def proxy_request
      pass_request
      pass_response
    end

    def pass_request
      @request.each do |line|
        if line.strip.empty?
          @output.write("X-Forwarded-Proto: https\r\n") if @ssl
          @output.write("X-Forwarded-For: #{@input.peeraddr[2]}\r\n")
          @output.write("X-Forwarded-Host: #{@request_headers['host']}\r\n")
          @output.write("X-Forwarded-Server: #{@input.addr[2]}\r\n")
        end
        @output.write(line)
      end
      content_length = @request_headers["content-length"].to_i
      @output.write(@input.read(content_length)) if content_length > 0
      @output.flush
    end

    def pass_response
      @response_headers = {}

      while line = @output.gets
#        line.force_encoding("ASCII-8BIT") if line.respond_to?(:force_encoding)
        @response_headers[$1.downcase] = $2 if line.strip =~ /^([^:]+):\s*(.*)$/
        @input.write(line)
        break if line.strip.empty?
      end

      content_length = @response_headers["content-length"].to_i
      if content_length > 0
        @input.write(@output.read(content_length))
      elsif @response_headers["connection"] == "close"
        begin
          @input.write(@output.read)
        rescue EOFError
        end
      end
      @input.flush
    rescue Errno::EPIPE, Errno::ECONNRESET
    end

    def parse_host(host)
      ary = host.split('.')
      ary.pop # extension + eventual :port
      ary # app name segments
    end

    def render(template, options = {})
      case options[:code] || 404
      when 404 then @input.write("HTTP/1.1 404 NOT FOUND\r\n")
      when 500 then @input.write("HTTP/1.1 500 SERVER ERROR\r\n")
      end
      @input.write("Content-Type: text/html\r\n")
      @input.write("Connection: close\r\n")
      @input.write("\r\n")

      tpl = ERB.new(File.read(template_path(template)))
      @input.write(tpl.result(binding))

      @input.flush
    end

    def template_path(template)
      File.join(ROOT, "templates", "#{template}.erb")
    end
  end
end
