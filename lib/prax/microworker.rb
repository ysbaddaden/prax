require 'thread'

module Prax
  class IOQueue < Queue
    def initialize
      super
      @check, @notify = IO.pipe
    end

    def push
      super.tap { @notify.write_nonblock('.') }
    end

    def pop(nonblock = false)
      super.tap { @check.read_nonblock(1) }
    end

    def to_io
      @check
    end
  end

  class MicroWorker
    DEFAULT_SIZE = 16

    attr_reader :queue, :size, :threads

    def initialize(size = DEFAULT_SIZE)
      @mutex = Mutex.new
      @queue = IOQueue.new
      @size = size
      @threads = size.times.map { spawn }
    end

    def stop(sync = false)
      @_stopping = true

      threads.each do |thread|
        thread[:notify].write_nonblock('.') if thread and thread[:notify]
      end

      threads.each do |thread|
        thread.join if thread
      end
    end

    def perform(*args)
    end

    def started?
      threads.any? and !@_stopping
    end

    protected
      def spawn
        Thread.new do
          check, notify = IO.pipe
          Thread.current[:notify] = notify

          begin
            work(check)
          ensure
            cleanup!
          end
        end
      end

      def work(check)
        ios = [queue, check]

        until @_stopping
          IO.select(ios).first.each do |io|
            break if io == check
            perform(*queue.pop(true)) rescue ThreadError nil
          end
        end
      end

      def cleanup!
        @mutex.synchronize do
          threads.delete(Thread.current)
          threads << spawn unless @_stopping or threads.size >= size
        end
      end
  end
end
