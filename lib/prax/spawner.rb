require "socket"
require 'prax/application'
require 'prax/monitor'

module Prax
  module Spawner
    extend self

    @mutex = Mutex.new
    @apps = []

    @monitor = Monitor.new
    @monitor.run

    def get(app_name)
      @mutex.synchronize do
        app = @apps.find { |_app| _app.realpath == realpath(app_name) }
        app ||= spawn(app_name) unless app
        @monitor.requested(app)
        app
      end
    end

    def stop
      @mutex.synchronize do
        @apps.pop.tap do |app|
          app.stop
          @monitor.pop(app)
        end until @apps.empty?
      end
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
        app.kill unless app.port_forwarding?
        raise
      end
  end
end
