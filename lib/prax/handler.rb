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
      render :cant_start_app, status: 500
    rescue NoSuchApp
      render :no_such_app, status: 404
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
        request.xip_host.split('.').last || :default
      else
        request.host.split('.').slice(-2) || :default
      end
    end
  end
end
