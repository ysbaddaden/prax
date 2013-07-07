require 'thread'

module Prax
  # Starts then maintains a pool of threads.
  #
  # Example:
  #
  #   queue = Queue.new
  #   workers = Prax::Workers.new(16) { handle_connection(queue.pop) }
  #   loop { queue << server.accept }
  #
  # A failing thread will be respawned automatically, unless you set exiting:
  #
  #   workers.exiting = true
  #
  class Workers
    attr_accessor :size, :threads, :exiting

    def initialize(size, &block)
      @mutex = Mutex.new
      @block = block
      self.size = size
      self.threads = size.times.map { spawn }
    end

    private
      def spawn
        Thread.new do
          begin
            @block.call
          rescue
            respawn unless exiting
            raise
          end
        end
      end

      def respawn
        @mutex.synchronize do
          threads.delete(Thread.current)
          threads << spawn if threads.size < size
        end
      end
  end
end

