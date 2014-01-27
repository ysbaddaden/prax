module Prax
  # NOTE: merge with Spawner? or rely on Spawner.apps?
  class Monitor
    attr_reader :apps

    def initialize
      @mutex = Mutex.new
      @apps = []
      @requests = {}
    end

    def run
      @thread = Thread.new do
        loop do
          sleep 30
          verify
        end
      end
    end

    def verify
      apps.each { |app| kill(app) if expired?(app) }
    rescue => ex
      Prax.logger.debug "Oops: #{ex}"
      raise if Prax::Config.debug?
    end

    def push(app)
      @mutex.synchronize { apps << app }
    end
    alias << push

    def pop(app)
      @mutex.synchronize do
        apps.delete(app)
        @requests.delete(app.name)
      end
    end

    def requested(app)
      @requests[app.name] = Time.now.utc
      push(app) unless apps.include?(app)
    end

    def expired?(app)
      @requests[app.name] && @requests[app.name] < Time.now.utc - Config.ttl
    end

    def kill(app)
      Prax.logger.info "Killing #{app.name}: expired TTL"
      app.kill unless app.port_forwarding?
      pop(app)
    end
  end
end
