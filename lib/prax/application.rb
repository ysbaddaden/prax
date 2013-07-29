require 'timeout'

module Prax
  class Application
    include Timeout

    attr_reader :app_name, :pid

    def initialize(app_name)
      @app_name = app_name.to_s
      raise NoSuchApp.new unless configured?
    end

    def start
      stop if restart?
      spawn unless started?
    end

    def kill(type = :TERM)
      Process.kill(type.to_s, @pid)
      Process.wait(@pid)
    rescue Errno::ECHILD
    ensure
      @socket = @pid = nil
    end

    def socket
      UNIXSocket.new(socket_path)
    end

    def started?
      File.exists?(socket_path)
    end

    def restart?
      !File.exists?(socket_path) and
        File.stat(socket_path).mtime < File.stat(File.join(realpath, 'tmp', 'restart.txt')).mtime
    end

    def configured?
      File.exists?(path) and File.directory?(realpath)
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
      def spawn
        env = {
          'PATH' => ENV['ORIG_PATH']
        }
        cmd = if gemfile?
                'bundle exec'
              else
                'ruby'
              end
        @pid = Process.spawn(env,
          "exec #{cmd} #{racker_path} --server #{socket_path}",
          chdir: realpath,
          out: [log_path, 'a'],
          err: [:child, :out],
          unsetenv_others: true,
          close_others: true
        )
        wait_for_process
      end

      def path
        @path ||= File.join(Config.host_root, app_name)
      end

      def wait_for_process
        timeout(30, CantStartApp) do
          sleep 0.01 while process_exists? and !started?
        end
      end

      def process_exists?
        Process.getpgid(@pid)
      rescue Errno::ESRCH
        false
      end
  end
end
