require 'rack'
require 'rack/builder'
require 'prax/microserver'
require 'prax/worker'
require 'prax/logger'
require 'prax/config'
require 'racker/handler'

module Racker
  include Prax::Logger

  class Pool < Prax::MicroWorker
    @@spawn_mutex = Mutex.new

    def perform(socket, ssl = nil)
      Handler.new(app, socket).handle
    end

    # TODO: rescue invalid config.ru apps.
    def app
      @app || @@spawn_mutex.synchronize do
        @app ||= begin
                   Racker.logger.debug("Building Rack app at #{config_path}")
                   Rack::Builder.parse_file(config_path).first
                 end
      end
    end

    def config_path
      @config_path ||= File.join(Dir.getwd, 'config.ru')
    end

    def logger
      Racker.logger
    end
  end

  class Server < Prax::MicroServer
    include Prax::Worker

    self.worker_class = Pool
    self.worker_size = Prax::Config.worker_threads_count

    def started
      servers = @listeners.map do |server|
        server.is_a?(UNIXSocket) ? server.path : "#{server.addr[2]}:#{server.addr[1]}"
      end
      Racker.logger.info("Racker is ready to receive connections on #{servers.join(' and ')}.")
    end
  end

  def self.run(options)
    @server = Server.new

    %w{INT TERM QUIT}.each { |signal| Signal.trap(signal) { exit } }
    Signal.trap('EXIT') { stop }

    if options[:server].start_with?('/')
      @server.add_unix_listener(options[:server])
    else
      @server.add_tcp_listener(*options[:server].split(':'))
    end

    @server.run
  end

  def self.stop(sync = true)
    @server.stop(sync)
  end
end
