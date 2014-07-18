require 'ipaddr'

module Prax
  class Host < String
    def ip?
      !(IPAddr.new(self) rescue nil).nil?
    end

    def xip?
      !!(self =~ Prax::XIP_RE)
    end
  end
end
