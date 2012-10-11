$: << File.dirname(__FILE__)


module Prax
  ROOT = File.expand_path("../..", __FILE__)
end

require 'prax/cli'
require 'prax/config'
require 'prax/handler'
require 'prax/logger'
require 'prax/racker'
require 'prax/server'
require 'prax/spawner'
require 'prax/version'
