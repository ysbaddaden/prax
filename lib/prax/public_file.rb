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
        type = MIME::Types.type_for(File.basename(file))
        return type.first.content_type if type.any?
      end
      DEFAULT_CONTENT_TYPE
    end
  end

  module PublicFile
    def public_file_exists?
      File.exists?(public_file_path) and !File.directory?(public_file_path)
    end

    def stream_public_file
      File.open(public_file_path, 'rb') do |file|
        @input.write "#{@http_version} 200 OK\r\n" +
          "Content-Type: #{content_type(file)}\r\n" +
          "Content-Length: #{file.size}\r\n" +
          "Connection: close\r\n\r\n"
        IO.copy_stream file, @input
      end
    end

    def public_file_path
      @public_file_path ||= begin
        if File.directory?(raw_public_file_path)
          File.join(raw_public_file_path, 'index.html')
        else
          raw_public_file_path
        end
      end
    end

    def raw_public_file_path
      @raw_public_file_path ||= begin
        uri = URI.unescape(URI(@request_uri).path)
        path = uri.split('/').reject { |part| part.empty? or part == '..' }
        File.join(Config.host_root, app_name.to_s, 'public', *path)
      end
    end
  end
end
