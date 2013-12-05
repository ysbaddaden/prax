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

    def get(app_segments)
      @mutex.synchronize do
        app = Application.find(app_segments)
        spawn(app) unless running?(app)

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
      def running?(app)
        @apps.any? { |a| a.realpath == app.realpath }
      end

      def spawn(app)
        app.assert_configured!
        @apps << app
        @monitor << app
        app.start unless app.port_forwarding?
        app
      rescue
        app.kill unless app.port_forwarding?
        raise
      end
  end
end
