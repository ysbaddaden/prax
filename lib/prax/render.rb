require 'rack/utils'
require "erb"

module Prax
  # FIXME: find a better name than Render!
  module Render
    def render(template_name, options)
      code, status = options[:status], Rack::Utils::HTTP_STATUS_CODES[options[:status]]
      html = render_to_string(template_name)

      socket.write "HTTP/1.1 #{code} #{status}\r\n" +
                   "Content-Type: text/html\r\n" +
                   "Content-Length: #{html.bytesize}\r\n" +
                   "Connection: close\r\n" +
                   "\r\n" +
                   html

      socket.close
    rescue Errno::EPIPE, Errno::ECONNRESET
    end

    def render_to_string(template_name)
      tpl = ERB.new(File.read(template_path(template_name)))
      tpl.result(binding)
    end

    def template_path(template_name)
      File.expand_path("../../../templates/#{template_name}.erb", __FILE__)
    end
  end
end
