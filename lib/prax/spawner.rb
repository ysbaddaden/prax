require "socket"
require "prax/config"

module Prax
  class Spawner
    attr_reader :app_name

    @@mutex = Mutex.new

    # Either spawns the Rack app (if properly configured) or permits to
    # connect to it via the socket if previously spawned.
    def initialize(app_name)
      @app_name = app_name.to_s

      # prevents threads to (re)spawn an app at the same time.
      @@mutex.synchronize do
        if start?
          Prax.logger.info("Starting app #{@app_name} (#{realpath})")
          spawn
        elsif restart?
          Prax.logger.info("Restarting app #{@app_name} (#{realpath})")
          kill
          spawn
        end
      end
    end

    # Spawns the app, then blocks until the socket is ready.
    #
    # TODO: notify an object in the main thread about the spawning app (that
    # object could kill all apps when prax is terminated, as well as killing
    # apps after some timeout).
    def spawn
      args, env = [], { 'PATH' => ENV['ORIG_PATH'] }

      # rbenv
      if rbenv?
        args = ['rbenv', 'exec']
        args << 'ruby' unless gemfile?
      end

      # bundler
      args += ['bundle', 'exec' ] if gemfile?

      # racker
      args += [
        File.join(ROOT, "bin", "racker"),
        "--server", socket_path,
        "--pid", pid_path,
        { :out => [ log_path, "a" ], :err => [ :child, :out ] }
      ]
      pid = nil

      # FIXME: chdir should happen in racker!
      Dir.chdir(realpath) { pid = Process.spawn(env, *args) }

      Process.detach(pid)
      wait_for_process(pid)
    end

    # Returns true if the Rack app hasn't been spawned yet.
    def start?
      !File.exists?(socket_path)
    end

    # Returns true if the Rack app must be restarted, because either
    # `tmp/always_restart.txt` is defined or `tmp/restart.txt` has been touched
    # since the last spawn.
    def restart?
      File.exists?(File.join(realpath, "tmp/always_restart.txt")) or
        File.stat(socket_path).mtime < File.stat(File.join(realpath, "tmp/restart.txt")).mtime
    rescue Errno::ENOENT
      false
    end

    # Gracefully stops a spawned Rack app.
    def kill
      if File.exists?(pid_path)
        pid = File.read(pid_path).strip.to_i
        Process.kill("TERM", pid)
        Process.wait
      end
    rescue Errno::ECHILD
      File.unlink(pid_path) if File.exists?(pid_path)
    end

    # Returns the UNIXSocket to the spawned app.
    def socket
      return nil unless File.exists?(socket_path)
      begin
        @socket ||= UNIXSocket.new(socket_path)
      rescue Errno::ECONNREFUSED => e
        Prax.logger.warn(e.to_s)
        File.unlink(socket_path)
        raise
      end
    end

    # Returns true if the app uses Bundler.
    def gemfile?
      File.exists?(File.join(realpath, "Gemfile"))
    end

    # Returns true if rbenv is found.
    def rbenv?
      `which rbenv` != ''
    end

    # Path to the Rack config file.
    def config_path
      @config_path ||= File.join(realpath, "config.ru")
    end

    # Path to the Rack socket.
    #
    # Note that we use the basename from the realpath of the symlink, which
    # permits to share a single instance of the app while serving it on
    # multiple domains.
    def socket_path
      @socket_path ||= File.join(Config.socket_root, "#{basename}.sock")
    end

    # Path to the PID of the spawned Rack app.
    def pid_path
      @pid_path ||= File.join(Config.pid_root, "#{basename}.sock")
    end

    # Path to the log of the spawned Rack app.
    def log_path
      @log_path ||= File.join(Config.log_root, "#{basename}.log")
    end

    # Real path to the app directory.
    def realpath
      @realpath ||= File.realpath(File.join(Config.host_root, app_name))
    end

    private
      def basename
        File.basename(realpath)
      end

      def wait_for_process(pid)
        Timeout.timeout(60) do
          sleep 0.1 while process_exists?(pid) && !File.exists?(socket_path)
        end
      end

      def process_exists?(pid)
        begin
          Process.getpgid(pid)
          true
        rescue Errno::ESRCH
          false
        end
      end
  end
end
