require "socket"
require "openssl"
require "prax/config"

module Prax
  class Spawner
    attr_reader :app_name

    # Either spawns the Rack app (if properly configured) or permits to
    # connect to it via the socket if previously spawned.
    def initialize(app_name)
      @app_name = app_name.to_s

      if start?
        Prax.logger.info("Starting app #{@app_name} (#{realpath})")
        spawn
      elsif restart?
        Prax.logger.info("Restarting app #{@app_name} (#{realpath})")
        kill
        spawn
      end
    end

    # Spawns the app, then blocks until the socket is ready.
    def spawn
      args = []
      args = [ "bundle", "exec" ] if gemfile?

      Dir.chdir(realpath) do
        pid = Process.spawn(*args, File.join(ROOT, "bin", "racker"),
          "--server", socket_path, "--pid", pid_path,
          [ :err, :out ] => [ "/tmp/#{app_name}.log", "a" ]
        )
        Process.detach(pid)
        wait_for_process(pid)
      end
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
    end

    # Returns the UNIXSocket to the spawned app.
    def socket
      return nil unless File.exists?(socket_path)
      @socket ||= UNIXSocket.new(socket_path)
    end

    # Returns true if the app uses Bundler.
    def gemfile?
      File.exists?(File.join(realpath, "Gemfile"))
    end

    # Path to the Rack config file.
    def config_path
      @config_path ||= File.join(realpath, "config.ru")
    end

    # Path to the Rack socket.
    #
    # Note that we use an MD5 on the realpath of the symlink, which permits
    # to share a single instance of the app on different domains.
    def socket_path
      @socket_path ||= "/tmp/prax_#{md5}.sock"
    end

    # Path to the PID of the spawned Rack app.
    def pid_path
      @pid_path ||= "/tmp/prax_#{md5}.pid"
    end

    # Real path to the app directory.
    def realpath
      @realpath ||= File.realpath(File.join(Config.host_root, app_name))
    end

    private
      def md5
        @md5 ||= OpenSSL::Digest::MD5.new(realpath).to_s
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
