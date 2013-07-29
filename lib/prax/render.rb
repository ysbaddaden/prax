require "erb"

module Prax
  # FIXME: find a better name than Render!
  module Render
    def render(template, options)
      tpl = ERB.new(File.read(template_path(template)))
      code = options[:code]
      socket.write "HTTP/1.1 #{code} #{Render.http_status(code)}\r\n" +
                   "Content-Type: text/html\r\n" +
                   "Connection: close\r\n" +
                   "\r\n" +
                   tpl.result(binding)
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
        File.join(ROOT, 'templates', "#{template}.erb")
      end
    end
  end
end
