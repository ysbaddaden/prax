require 'prax/microserver'
require 'prax/worker'
require 'racker/handler'

module Racker
  class Pool < MicroWorker
    def perform(socket)
      Handler.new(socket)
    end
  end

  class Server < MicroServer
    include Worker

    self.worker_class = Pool
    self.worker_size = 4
  end

  def self.run(socket_path)
    @server = Server.new
    @server.add_unix_listener(socket_path)
    @server.run
  end

  def self.stop(sync = true)
    @server.stop(sync)
  end
end
