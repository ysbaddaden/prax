#! /usr/bin/env ruby
$:.unshift File.expand_path('../..', File.realpath(__FILE__))
foreground = ARGV.include?('-f') || ARGV.include?('--foreground')

unless foreground
  puts "Starting prax in the background."
  Process.daemon
end

require 'prax'
#Thread.abort_on_exception = Prax::Config.debug?
Prax.run(daemon: !foreground)

