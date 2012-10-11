module Prax
  class CLI
    def initialize(*args)
      @arguments = args
    end

    def run
      # Set process title:
      $0 = 'praxd'

      # Run the server:
      Prax::Server.run
    end
  end
end
