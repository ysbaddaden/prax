require 'prax/microworker'

module Prax
  module Worker

    module ClassMethods
      attr_accessor :worker_class, :worker_size
    end

    def self.included(klass)
      klass.extend ClassMethods
      klass.class_eval { @@mutex = Mutex.new }
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
