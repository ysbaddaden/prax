require 'rack/utils'
require "erb"

module Prax
  # FIXME: find a better name than Render!
  module Render
    def render(template, options)
      tpl  = ERB.new(File.read(template_path(template)))
      code = options[:code]
      html = tpl.result(binding)
      socket.write "HTTP/1.1 #{code} #{Rack::Utils::HTTP_STATUS_CODES[code]}\r\n" +
                   "Content-Type: text/html\r\n" +
                   "Content-Length: #{html.bytesize}\r\n" +
                   "Connection: close\r\n" +
                   "\r\n" +
                   html
      socket.close
    rescue Errno::EPIPE, Errno::ECONNRESET
    end

    def template_path(template)
      File.expand_path("../../../templates/#{template}.erb", __FILE__)
    end
  end
end
