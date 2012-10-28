require "erb"
require "timeout"

module Prax
  class Handler
    class NoSuchExt < StandardError; end
    class NoSuchApp < StandardError; end
    class CantStartApp < StandardError; end

    attr_reader :input, :ssl

    def initialize(input, ssl = nil)
      @input = input
      @ssl = ssl
    end

    def run
      parse_request
      if @request.any?
        spawn_app
        if @output
          pass_request
          pass_response
        end
      end
    rescue NoMethodError => e
      Prax.logger.warn(e.message + "\n" + e.backtrace.join("\n"))
    ensure
      @output.close if @output
    end

    def spawn_app
      @ext, @app_name = parse_host

      unless Config.ip?(@request_headers["host"])
        if Config.xip?(@request_headers["host"])
          @app_name = Config.xip_app_name(@request_headers["host"])
        else
          raise NoSuchExt.new unless Config.supported_ext?(@ext)
        end

        if Config.configured_app?(@app_name)
          @spawner = Spawner.new(@app_name)
        end
      end

      unless @spawner
        if Config.configured_default_app?
          @app_name = :default
          @spawner = Spawner.new(:default)
        else
          raise NoSuchApp.new
        end
      end

      @output = @spawner.socket or raise CantStartApp.new

    rescue NoSuchExt => e
      Prax.logger.debug("No such extension: #{@ext}")
      render(:no_such_ext)
    rescue NoSuchApp => e
      Prax.logger.debug("No such application: #{@app_name}")
      render(:no_such_app)
    rescue CantStartApp => e
      Prax.logger.debug("Can't start application: #{@app_name}")
      render(:cant_start_app)
#    rescue => exception
#      @exception = exception
#      render(:spawn_error)
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

        while line = input.gets
#          line.force_encoding("ASCII-8BIT") if line.respond_to?(:force_encoding)
          @request_headers[$1.downcase] = $2 if line.strip =~ /^([^:]+):\s*(.*)$/
          @request << line
          break if line.strip.empty?
        end
      end
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
    end

    def parse_host
      ary = @request_headers["host"].split(".")
      [ ary.pop.split(":").first, ary.pop ]
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
