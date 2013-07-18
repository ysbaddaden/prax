require 'prax/microserver'
require 'prax/worker'
require 'prax/config'
require 'prax/handler'

module Prax
  class Pool < MicroWorker
    def perform(socket, ssl)
      Handler.new(socket, ssl)
    end
  end

  class Server < MicroServer
    include Worker

    self.worker_class = Pool
    self.worker_size = Config.threads_count

    def initialize
      @ssl_crt = File.expand_path('../../ssl/server.crt')
      @ssl_key = File.expand_path('../../ssl/server.key')
      super
    end
  end

  def self.run
    @server = Server.new
    @server.add_tcp_listener(Config.http_port)
    @server.add_ssl_listener(Config.https_port)
    @server.run
  end

  def self.stop(sync = true)
    @server.stop(sync)
  end
end
