#! /usr/bin/env ruby
$:.unshift File.expand_path("../..", File.realpath(__FILE__))

require "optparse"
require "racker"

options = {
  :server => "0.0.0.0:9292"
}

cli_parser = OptionParser.new do |opt|
  opt.banner = "Usage: racker [OPTIONS]"
  opt.separator ""
  opt.separator "Options:"

  opt.on("-s SERVER", "--server SERVER", "Either host:port or /path/to/socket.sock") do |server|
    options[:server] = server
  end

  #opt.on("-p PATH", "--pid PATH", "Path to PID file") do |path|
  #  options[:pid] = path
  #end

  #opt.on("-l PATH", "--log PATH", "Path to logger file") do |path|
  #  options[:log] = path
  #end
end
cli_parser.parse!

Thread.abort_on_exception = ENV['PRAX_DEBUG']
Racker.run(options)

