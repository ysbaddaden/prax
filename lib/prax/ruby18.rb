# Polyfills for missing methods in Ruby 1.8

if !File.respond_to?(:realpath)
  require "pathname"

  def File.realpath(path)
    Pathname.new(path).realpath
  end
end

if !Process.respond_to?(:spawn)
  require "rubygems"
  require "sfl"
end
