module Prax
  class CLI
    def initialize(*args)
      @arguments = args
    end

    def run
      $0 = 'praxd'
      Prax::Server.run
    end
  end
end
