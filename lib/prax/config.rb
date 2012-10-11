require 'ipaddr'

module Prax
  module Config
    class << self
      # Directory where links to apps are stored. Defaults to `$HOME/.prax`
      def host_root
        @host_root ||= ENV["PRAX_HOST_ROOT"] || File.join(ENV["HOME"], ".prax")
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

      # An array of top level extensions to serve. Any other extension
      # will raise an error. Please configure the `PRAX_DOMAINS` environment
      # variable to configure the domains the serve.
      #
      # Defaults to `.dev`.
      def domains
        @domains ||= (ENV["PRAX_DOMAINS"] || "dev").split(",").collect(&:strip)
      end

      # Returns true if the extention is known to Prax.
      def supported_ext?(ext)
        domains.include?(ext.to_s)
      end

      # Returns true if a given app is available (a link in host_root that leads
      # to a real directory.
      def configured_app?(app_name)
        path = File.join(host_root, app_name.to_s)
        File.exists?(path) and File.directory?(File.realpath(path))
      end

      # Returns true if a default app is available.
      def configured_default_app?
        configured_app?(:default)
      end

      def debug?
        !!ENV["PRAX_DEBUG"]
      end

      def thread?
        !debug?
      end

      def ip?(str)
        host = str.split(":").first
        !(IPAddr.new(host) rescue nil).nil?
      end

      def xip?(str)
        !xip_host(str).nil?
      end


      def xip_app_name(str)
        xip_host(str).split(".").last
      end


      private
      def xip_host(str)
        host = str.split(":").first
        $1 if host =~ /^(.*?)\.?\d+.\d+\.\d+\.\d+\.xip\.io$/
      end
    end
  end
end
