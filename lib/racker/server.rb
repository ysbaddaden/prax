require 'socket'
require 'rack'
require 'rack/builder'
require 'racker/logger'
require 'prax/workers'
require 'racker/handler'

module Racker
  class Server
    attr_reader :queue, :server, :workers

    def self.run(*args)
      new(*args).run
    end

    def initialize(options = {})
      trap_signals
      handle_options(options)
      spawn_workers
      spawn_server(options)
    rescue
      finalize
      raise
    end

    def run
      Racker.logger.info("Server ready to receive connections")
      loop { queue << server.accept }
    end

    def finalize
      workers.exiting = true
      server.close if server
      File.unlink(@pid_path)    if @pid_path    and File.exists?(@pid_path)
      File.unlink(@socket_path) if @socket_path and File.exists?(@socket_path)
    end

    def app
      @mutex.synchronize { @app ||= spawn_app }
    end

    private
      def spawn_server(options)
        Racker.logger.debug("Starting server on #{options[:server]}")

        if options[:server] =~ %r{^/}
          @socket_path = options[:server]
          @server = UNIXServer.new(@socket_path)
        else
          host, port = options[:server].split(':', 2)
          @server = TCPServer.new(host, port || 9292)
        end
      end

      def spawn_workers
        @mutex, @queue = Mutex.new, Queue.new
        @workers = Prax::Workers.new(4) do
          loop { Handler.new(app, queue.pop).handle_connection }
        end
      end

      def spawn_app
        config_path = Dir.getwd + "/config.ru"
        Racker.logger.debug("Building Rack app at #{config_path}")
        app, _ = Rack::Builder.parse_file(config_path)
        app
      rescue => err
        Racker.logger.error("Error parsing config.ru: #{err}")
        nil
      end

      def handle_options(options)
        store_pid(options[:pid]) if options[:pid]
        Racker.logger = ::Logger.new(options[:log]) if options[:log]
      end

      def trap_signals
        Signal.trap("INT")  { exit }
        Signal.trap("TERM") { exit }
        Signal.trap("QUIT") { exit }
        Signal.trap("EXIT") { finalize }
      end

      def store_pid(pid_path)
        @pid_path = pid_path
        File.open(@pid_path, "w") { |f| f.write(Process.pid) }
      end
  end
end
