require "erb"
require "timeout"

module Prax
  class Handler
    class NoSuchApp < StandardError; end
    class CantStartApp < StandardError; end

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

    def public_file_path
      @public_file_path ||=
        File.join(Config.host_root, app_name, "public", @request_uri)
    end

    def public_file_exists?
      return File.exists?(public_file_path) && !File.directory?(public_file_path)
    end

    def stream_public_file
      @input.write "#{@http_version} 200 OK\r\n"
      @input.write "Connection: close\r\n\r\n"
      @input.write File.read(public_file_path, mode: "rb")
    end

    def app_name
      @app_name ||= lambda {
        host, full_app_name = @request_headers["host"], parse_host

        unless Config.ip?(host)
          return Config.xip_app_name(host) if Config.xip?(host)
          app_name = Config.configured_app?(full_app_name)
          return app_name if app_name != false
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
        @output.write("X-Forwarded-Proto: https\r\n") if line.strip.empty? and @ssl
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

    def parse_host
      @request_headers["host"].gsub /(.+)(\..+$)/, '\1'
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
