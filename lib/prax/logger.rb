require 'logger'
require_relative 'config'

module Prax
  class Logger < ::Logger
    def initialize(*args)
      super
      @level = Config.debug? ? DEBUG : INFO
    end
  end

  class << self
    # Configure the default logger.
    def logger
      @logger ||= Prax::Logger.new(STDOUT)
    end

    # Allow replacement of the logger.
    def logger=(logger)
      @logger = logger
    end
  end
end
