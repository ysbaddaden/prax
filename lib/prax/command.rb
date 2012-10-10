#! /usr/bin/env ruby

require_relative 'server'
Prax::Server.run

#Process.exec("ruby", File.expand_path("../../lib/server.rb", __FILE__), *ARGV)
