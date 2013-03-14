require "prax/config"
require "logger"

module Prax
  class MultiIO
    def initialize(*targets)
      @targets = targets
    end

    def write(*args)
      @targets.each { |target| target.write(*args) }
    end

    def close
      @target.each(&:close)
    end
  end

  class Logger < ::Logger
    def initialize(*args)
      super
      @level = Config.debug? ? DEBUG : INFO
    end
  end

  def self.logger
    @logger ||= begin
      $stdout.sync = true
      log = File.open(File.join(Config.log_root, "prax.log"), "a")
      Prax::Logger.new(MultiIO.new($stdout, log))
    end
  end

  def self.logger=(logger)
    @logger = logger
  end
end

