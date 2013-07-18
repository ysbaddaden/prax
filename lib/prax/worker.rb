require 'prax/microworker'

module Prax
  module Worker
    attr_accessor :worker_class
    attr_accessor :worker_size

    def self.included do |klass|
      klass.eval { @@mutex = Mutex.new }
    end

    def pool
      @@mutex.synchronize do
        @pool ||= self.class.worker_class.new(self.class.worker_size)
      end
    end

    def serve(*args)
      pool.queue << args
    end

    def stop(sync = false)
      super
      pool.stop(sync)
    end
  end
end
