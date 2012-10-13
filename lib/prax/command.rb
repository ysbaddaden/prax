#! /usr/bin/env ruby
$:.unshift File.expand_path("../..", File.realpath(__FILE__))

require "prax/server"
Prax::Server.run
