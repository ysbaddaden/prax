require 'logger'

module Racker
  def self.logger
    @logger ||= begin
      $stdout.sync = true
      ::Logger.new($stdout)
    end
  end

  def self.logger=(logger)
    @logger = logger
  end
end
