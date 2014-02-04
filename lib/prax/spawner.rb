require "socket"
require 'prax/application'
require 'prax/monitor'

module Prax
  # FIXME: remove the app from @apps when it's killed (eg: ttl expired in monitor).
  module Spawner
    extend self

    @mutex = Mutex.new
    @apps = []

    @monitor = Monitor.new
    @monitor.run

    def get(app_name)
      @mutex.synchronize do
        app = @apps.find { |_app| _app.realpath == realpath(app_name) }

        if app
          app.kill if app.restart?
        else
          app = spawn(app_name)
        end

        @monitor.requested(app)
        app
      end
    end

    # FIXME: can't synchronize threads when process is exiting, but we need
    #   applications to be killed.
    def stop
      #@mutex.synchronize do
        @apps.pop.tap do |app|
          app.kill(:TERM, false)
          @monitor.pop(app) rescue ThreadError
        end until @apps.empty?
      #end
    end

    private

      def realpath(app_name)
        File.realpath(File.join(Config.host_root, app_name.to_s))
      end

      def spawn(app_name)
        @apps << app = Application.new(app_name)
        @monitor << app
        app.start unless app.port_forwarding?
        app
      rescue
        app.kill if app && !app.port_forwarding?
        raise
      end
  end
end
