require 'uri'
begin
  require 'mime/types'
rescue LoadError
end

module Prax
  module ContentType
    DEFAULT_CONTENT_TYPE = 'application/octet-stream'

    def content_type(file)
      if defined?(MIME::Types)
        MIME::Types.type_for(File.basename(file)).first.content_type
      else
        DEFAULT_CONTENT_TYPE
      end
    end
  end

  class PublicFile
    include ContentType
    attr_reader :request, :app_name

    def initialize(request, app_name)
      @request, @app_name = request, app_name
    end

    def exists?
      File.exists?(file_path) and !File.directory?(file_path)
    end

    def stream_to(io)
      File.open(file_path, 'rb') do |file|
        io.write "#{request.http_version} 200 OK\r\n" +
                 "Content-Type: #{content_type(file)}\r\n" +
                 "Content-Length: #{file.size}\r\n" +
                 "Connection: close\r\n\r\n"
        IO.copy_stream file, io
      end
    end

    def file_path
      @file_path ||= begin
        if File.directory?(raw_file_path)
          File.join(raw_file_path, 'index.html')
        else
          raw_file_path
        end
      end
    end

    def raw_file_path
      @raw_file_path ||= File.join(Config.host_root, app_name, 'public', *sanitized_uri)
    end

    def sanitized_uri
      uri = URI.unescape(URI(request.uri).path)
      uri.split('/').reject { |part| part.empty? or part == '..' }
    end
  end
end
