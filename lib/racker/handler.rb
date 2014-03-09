require 'rack/utils'
require 'prax/request'
require 'prax/render'

module Racker

  class Handler
    include Prax::Render
    attr_reader :app, :socket, :code, :headers, :body

    def initialize(app, socket)
      @app, @socket = app, socket
    end

    def handle
      @code, @headers, @body = catch_error { app.call(env) }
      write_response
    rescue Errno::EPIPE, Errno::EIO, Errno::ECONNRESET, IOError
    ensure
      finalize
    end

    def request
      @request ||= Prax::Request.new(socket, false)
    end

    def finalize
      unless socket.closed?
        socket.flush
        socket.close
      end
      body.close if body.respond_to?(:close)
      env['rack.input'].close if @env && env['rack.input']
    end

    def env
      @env ||= request_to_env
    end

    private
      def catch_error
        begin
          yield
        rescue => exception
          render_error(exception)
          raise
        end
      end

      def write_response
        status = Rack::Utils::HTTP_STATUS_CODES[code]
        socket.write "#{env['HTTP_VERSION']} #{code} #{status}\r\n"

        response_headers.each do |key, value|
          value.split(/\n/).each { |v| socket.write "#{key}: #{v}\r\n" }
        end
        socket.write "\r\n"

        body.each { |b| socket.write b }
      end

      def response_headers
        headers.merge 'Connection' => 'close'
      end

      def request_to_env
        {
          'rack.version' => [1, 1],
          'rack.multithread' => true,
          'rack.multiprocess' => false,
          'rack.run_once' => false,
          'rack.errors' => STDERR,
          'rack.logger' => Racker.logger,
          'rack.url_scheme' => 'http',
          'rack.input' => request.body_as_rewindable_input,
          'HTTP_VERSION' => request.http_version,
          'REMOTE_ADDR' => request.remote_addr,
          'SERVER_SOFTWARE'=> 'racker 0.1.0',
          'SERVER_PROTOCOL' => request.http_version,
          'SERVER_NAME' => request.host,
          'SERVER_PORT' => request.port.to_s,
          'SCRIPT_NAME' => '',
          'REQUEST_METHOD' => request.method,
          'REQUEST_URI' => request.uri,
          'REQUEST_PATH' => request.path_info,
          'PATH_INFO' => request.path_info,
          'QUERY_STRING' => request.query_string,
        }.merge headers_to_env
      end

      def headers_to_env
        request.headers.inject({}) do |acc, ( header, value )|
          case name = header.upcase.gsub('-', '_')
          when 'CONTENT_TYPE'
            acc['CONTENT_TYPE'] = value
          when 'CONTENT_LENGTH'
            acc['CONTENT_LENGTH'] = value.to_i
          else
            acc["HTTP_#{name}"] = value
          end
          acc
        end
      end

      def render_error(exception)
        status = Rack::Utils::HTTP_STATUS_CODES[500]
        socket.write "#{env["HTTP_VERSION"]} 500 #{status}\r\n" +
                     "Connection: close\r\n" +
                     "Content-Type: text/plain\r\n" +
                     "X-Racker-Exception: 1\r\n" +
                     "\r\n" +
                     exception.class.name + ": " + exception.message + "\n\n" +
                     exception.backtrace.join("\n") + "\n"
        socket.flush
      end
  end
end
