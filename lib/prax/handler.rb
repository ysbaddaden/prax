require "prax/request"
require "prax/response"
require "prax/render"
require "prax/public_file"

module Prax
  class Handler
    include Render

    attr_reader :request, :socket, :ssl

    def initialize(socket, ssl = nil)
      @socket, @ssl = socket, ssl
    end

    def handle
      file = PublicFile.new(request, app_name)
      if file.exists?
        file.stream_to(socket)
      else
        request.proxy_to(connection)  # socket => connection
        response.proxy_to(socket)     # socket <= connection
      end
    rescue CantStartApp
      if app.port
        render :port_forwarding_connection_error, status: 500
      else
        render :cant_start_app, status: 500
      end
    rescue NoSuchApp
      render :no_such_app, status: 404
    rescue PortForwardingConnectionError
      render :port_forwarding_connection_error, status: 500
    rescue Timeout::Error
      render :timeout, status: 500
    ensure
      socket.close unless socket.closed?
    end

    def request
      @request ||= Request.new(socket, ssl)
    end

    def response
      @response ||= Response.new(connection)
    end

    def connection
      @connection ||= app.socket
    end

    def app
      @app ||= Spawner.get(app_name)
    end

    def app_name
      @app_name ||= if request.host.ip?
                      :default
                    elsif request.host.xip?
                      resolve_fqdn(request.xip_host) || :default
                    else
                      resolve_fqdn(request.host) || :default
                    end
    end

    def resolve_fqdn(host)
      segments = host.split('.')
      (segments.size - 1).times do |index|
        app_name = segments[index...-1].join('.')
        return app_name if Application.exists?(app_name)
      end
      nil
    end
  end
end
