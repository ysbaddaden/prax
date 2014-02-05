module Prax
  module HTTP
    def parse_http_headers
      while line = socket.gets
        headers << [$1, $2] if line.strip =~ /^([^:]+):\s*(.*)$/
        break if line.strip.empty?
      end
    end

    def headers
      @headers ||= []
    end

    def header(name)
      headers.each { |header, value| return value if header.upcase == name.upcase }
      return nil
    end

    def header?(name)
      !header(name).nil?
    end

    def content_length
      @content_length ||= header('Content-Length').to_i
    end
  end
end
