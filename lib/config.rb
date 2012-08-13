module Prax
  module Config
    # Directory where links to apps are stored. Defaults to `$HOME/.pow` in
    # order to be compatible with Pow!!
    def self.host_root
      @host_root ||= ENV["PRAX_HOST_ROOT"] || File.join(ENV["HOME"], ".pow")
    end

    # The host to run the HTTP server on. Defaults to `0.0.0.0` (ie. all available
    # interfaces).
    def self.http_host
      @http_host ||= ENV["PRAX_HTTP_HOST"] || "0.0.0.0"
    end

    # The port to run the HTTP server on. Defaults to 20559.
    def self.http_port
      @http_port ||= (ENV["PRAX_HTTP_PORT"] || 20559).to_i
    end

    # An array of top level extensions to serve. Any other extension
    # will raise an error. Please configure the `PRAX_DOMAINS` environment
    # variable to configure the domains the serve.
    #
    # Defaults to `.dev`.
    def self.domains
      @domains ||= (ENV["PRAX_DOMAINS"] || "dev").split(",").collect(&:strip)
    end

    # Returns true if the extention is known to Prax.
    def self.supported_ext?(ext)
      self.domains.include?(ext.to_s)
    end

    # Returns true if a given app is available (a link in host_root that leads
    # to a real directory.
    def self.configured_app?(app_name)
      path = File.join(host_root, app_name.to_s)
      File.exists?(path) and File.directory?(File.realpath(path))
    end

    # Returns true if a default app is available.
    def self.configured_default_app?
      configured_app?(:default)
    end

    def self.debug?
      !!ENV["PRAX_DEBUG"]
    end

    def self.thread?
      !debug?
    end
  end
end
