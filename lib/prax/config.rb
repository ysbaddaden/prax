require "ipaddr"

module Prax
  module Config
    class << self
      # Directory where links to apps are stored. Defaults to `$HOME/.prax`
      def host_root
        @host_root ||= ENV["PRAX_HOST_ROOT"] || File.join(ENV["HOME"], ".prax")
      end

      # Directory where logs are stored. Defaults to `$HOME/.prax/_logs`
      def log_root
        @log_root ||= ENV["PRAX_LOG_ROOT"] || root("_logs")
      end

      # Directory where sockets are stored. Defaults to `$HOME/.prax/_sockets`
      def socket_root
        @socket_root ||= ENV["PRAX_SOCKET_ROOT"] || root("_sockets")
      end

      # The host to run the HTTP server on. Defaults to `0.0.0.0` (ie. all
      # available interfaces).
      def http_host
        @http_host ||= ENV["PRAX_HTTP_HOST"] || nil
      end

      # The port to run the HTTP server on. Defaults to 20559.
      def http_port
        @http_port ||= (ENV["PRAX_HTTP_PORT"] || 20559).to_i
      end

      # The port to run the HTTPS server on. Defaults to 20558.
      def https_port
        @https_port ||= (ENV["PRAX_HTTPS_PORT"] || 20558).to_i
      end

      def threads_count
        @threads_count ||= (ENV["PRAX_THREADS"] || 16).to_i
      end

      def worker_threads_count
        @worker_threads_count ||= (ENV["PRAX_APP_THREADS"] || 4).to_i
      end

      # Time after which an inactive app may be killed, in minutes. Defaults to
      # 10 minutes.
      def ttl
        @ttl ||= (ENV['PRAX_TTL'] || 10).to_i * 60
      end

      def racker_path
        File.expand_path('../../../bin/racker', __FILE__)
      end

      def debug?
        !!ENV["PRAX_DEBUG"]
      end

      private
        def root(dirname)
          path = File.join(host_root, dirname)
          Dir.mkdir(path) unless File.exists?(path)
          path
        end
    end
  end
end
