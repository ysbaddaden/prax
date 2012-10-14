require "prax/config"
require "logger"

module Prax
  class Logger < ::Logger
    def initialize(*args)
      super
      @level = Config.debug? ? DEBUG : INFO
    end
  end

  def self.logger
    @logger ||= Prax::Logger.new(STDOUT)
  end

  def self.logger=(logger)
    @logger = logger
  end
end

