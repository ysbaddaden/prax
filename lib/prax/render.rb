require "erb"

module Prax
  # FIXME: find a better name than Render!
  module Render
    def render(template, options)
      tpl  = ERB.new(File.read(Render.template_path(template)))
      code = options[:code]
      html = tpl.result(binding)
      socket.write "HTTP/1.1 #{code} #{Render.http_status(code)}\r\n" +
                   "Content-Type: text/html\r\n" +
                   "Content-Length: #{html.bytesize}\r\n" +
                   "Connection: close\r\n" +
                   "\r\n" +
                   html
      socket.close
    rescue Errno::EPIPE, Errno::ECONNRESET
    end

    class << self
      def http_status(code)
        case code
        when 404 then 'NOT FOUND'
        when 500 then 'SERVER ERROR'
        end
      end

      def template_path(template)
        File.expand_path("../../../templates/#{template}.erb", __FILE__)
      end
    end
  end
end
