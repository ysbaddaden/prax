require 'uri'
require 'rack/file'
require 'rack/utils'

module Prax
  class PublicFile
    attr_reader :request, :app_name

    def initialize(request, app_name)
      @request, @app_name = request, app_name.to_s
    end

    def exists?
      File.exists?(file_path) and !File.directory?(file_path)
    end

    def stream_to(io)
      file = Rack::File.new(nil)
      file.path = file_path
      code, headers, body = file.serving(request.to_env)

      headers["Connection"] = "close"

      io.write "#{request.http_version} #{code} #{Rack::Utils::HTTP_STATUS_CODES[code]}\r\n"
      io.write headers.map { |h, v| "#{h}: #{v}" }.join("\r\n")
      io.write "\r\n\r\n"
      body.each { |part| io.write part }
    rescue Errno::ECONNRESET
    end

    def file_path
      @file_path ||= if File.directory?(raw_file_path)
                       File.join(raw_file_path, 'index.html')
                     else
                       raw_file_path
                     end
    end

    def raw_file_path
      @raw_file_path ||= File.join(Config.host_root, app_name, 'public', *sanitized_uri)
    end

    def sanitized_uri
      URI.unescape(URI(request.uri).path)
        .split('/')
        .reject { |part| part.empty? or part == '..' }
    end
  end
end
