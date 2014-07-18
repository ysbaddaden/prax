require 'thread'

module Prax
  class IOQueue #< Queue
    def initialize
      super
      @check, @notify = IO.pipe
      @queue = Queue.new
    end

    def push(msg)
      @queue.push(msg).tap { @notify.write_nonblock('.') }
    end
    alias << push

    def pop(nonblock = false)
      @queue.pop(nonblock).tap { @check.read_nonblock(1) }
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
          rescue => exception
            log_error(exception)
            raise
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
            args = begin
                     queue.pop(true)
                   rescue ThreadError
                     nil
                   end
            perform(*args) unless args.nil?
          end
        end
      end

      def cleanup!
        @mutex.synchronize do
          threads.delete(Thread.current)
          threads << spawn unless @_stopping or threads.size >= size
        end
      end

      def log_error(exception)
        logger.error exception.class.name + ": " + exception.message + "\n  " + exception.backtrace.join("\n  ")
        logger.info "Respawning failed worker"
      end
  end
end
