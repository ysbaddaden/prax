require "prax/config"
require "logger"

module Prax
  module Logger
    def self.included(klass)
      klass.extend ClassMethods
    end

    module ClassMethods
      def logger
        @logger ||= begin
          io = @daemon ? File.open(File.join(Config.log_root, 'prax.log'), 'a') : STDOUT
          io.sync = true if io.respond_to?(:sync)
          logger = ::Logger.new(io)
          logger.level = Config.debug? ? ::Logger::DEBUG : ::Logger::INFO
          logger
        end
      end

      def logger=(logger)
        @logger = logger
      end
    end
  end
end

