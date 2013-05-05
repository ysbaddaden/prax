#! /usr/bin/env ruby
require File.expand_path("../ruby18", __FILE__) if RUBY_VERSION < "1.9"
$:.unshift File.expand_path("../..", File.realpath(__FILE__))

unless ARGV.include?('-f') or ARGV.include?('--foreground')
  puts "Starting prax in the background."
  Process.daemon
end

require "prax/server"
Prax::Server.run

