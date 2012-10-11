require 'docopt'


module Prax
  class CLI
    USAGE = <<-USAGE
Rack proxy server for development.

Usage:
  #{$0} run [-d | --debug]
  #{$0} racker (--server=<server>) (--pid=<pid>) [--log=<log>] [-d | --debug]
  #{$0} --version
  #{$0} -h | --help

Options:
  -h --help          Show this screen.
  --version          Show version.
  -d --debug         Show debug output.
  --server=<server>  The server to bind to. Either a socket or a host:port pair.
  --pid=<pid>        The pid file.
  --log=<log>        The log file.
USAGE

    class << self
      def run(*args)
        new(*args).run
      end
    end

    def initialize(*args)
      begin
        @options = Docopt::docopt(USAGE, {version: Version::FULL})
      rescue Docopt::Exit => e
        puts e.message
        exit
      end
    end

    def run
      # Enable debug:
      ENV["PRAX_DEBUG"] = "1" if @options["--debug"]


      if @options["run"] == true
        # Set process title:
        $0 = 'prax: praxd'

        # Run the server:
        Prax::Server.run
      elsif @options["racker"]
        $0 = 'prax: racker'

        # Run Racker:
        Racker.run(
          server: @options["--server"],
          pid: @options["--pid"],
          log: @options["--log"]
        )
      end
    end
  end
end
