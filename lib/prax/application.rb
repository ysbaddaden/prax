require 'timeout'

module Prax
  class Application
    include Timeout

    attr_reader :app_name, :pid, :port
    alias name app_name

    def self.exists?(app_name)
      File.exists?(File.join(Config.host_root, app_name))
    end

    def initialize(app_name)
      @app_name = app_name.to_s
      raise NoSuchApp.new unless configured?
    end

    def start
      spawn unless started?
    end

    def kill(type = :TERM, wait = true)
      return if port_forwarding? || !@pid

      Prax.logger.debug("Killing #{app_name} (#{@pid})...")
      Process.kill(type.to_s, @pid)

      if wait
        Process.wait(@pid)
      else
        Process.detach(@pid)
      end
    rescue Errno::ECHILD
    ensure
      @socket = @pid = @port = nil
    end

    def socket
      return TCPSocket.new('localhost', @port) if port_forwarding?

      begin
        UNIXSocket.new(socket_path)
      rescue Errno::ENOENT, Errno::ECONNREFUSED
        force_restart
        UNIXSocket.new(socket_path)
      end
    end

    def started?
      File.exists?(socket_path)
    end

    def restart?
      return false if port_forwarding?
      return true unless started?
      restart = File.join(realpath, 'tmp', 'restart.txt')
      File.exists?(restart) && File.stat(socket_path).mtime < File.stat(restart).mtime
    end

    def configured?
      if File.exists?(path)
        if File.symlink?(path) || File.directory?(path)
          # rack app
          return File.directory?(realpath)
        else
          # port forwarding
          port = File.read(path).strip.to_i
          if port > 0
            @port = port
            return true
          end
        end
      end
      return false
    end

    def port_forwarding?
      !!@port
    end

    def socket_path
      @socket_path ||= File.join(Config.socket_root, "#{File.basename(realpath)}.sock")
    end

    def log_path
      @log_path ||= File.join(Config.log_root, "#{File.basename(realpath)}.log")
    end

    def realpath
      @realpath ||= File.realpath(path)
    end

    private

      def force_restart
        Prax.logger.info "Forcing restart of #{app_name} (#{realpath})"
        kill
        clean_stalled_socket
        spawn
      end

      def spawn
        Prax.logger.info "Spawning application '#{app_name}' [#{realpath}]"
        Prax.logger.debug command.inspect

        @pid = Process.spawn(env, *command,
          chdir: realpath,
          out: [log_path, 'a'],
          err: [:child, :out],
          unsetenv_others: true,
          close_others: true
        )
        wait_for_process

        Prax.logger.debug "Application '#{app_name}' is ready on unix:#{socket_path}"
      end

      def env
        { 'PATH' => ENV['ORIG_PATH'], 'PRAX_DEBUG' => ENV['PRAX_DEBUG'], 'HOME' => ENV['HOME'] }
      end

      def command
        @command ||= [Config.racker_path, "--server", socket_path]
      end

      def path
        @path ||= File.join(Config.host_root, app_name)
      end

      def gemfile?
        File.exists?(File.join(realpath, 'Gemfile'))
      end

      def wait_for_process
        timeout(30, CantStartApp) do
          sleep 0.01 while process_exists? && !started?
        end
      end

      def process_exists?
        Process.getpgid(@pid)
      rescue Errno::ESRCH
        false
      end

      def clean_stalled_socket
        return unless File.exists?(socket_path)
        Prax.logger.warn("Cleaning stalled socket: #{socket_path}")
        File.unlink(socket_path)
      end
  end
end
