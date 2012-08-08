require "socket"
#require "ap"

server = TCPServer.new("localhost", 20559)

loop {
  Thread.start(server.accept) do |input|
    if ARGV[0] == "--tcp"
      output = TCPSocket.new("localhost", 9292)
    else
      output = UNIXSocket.new("/tmp/rack.sock")
    end

    # SOCKET > RACK SERVER
    content_length = 0
    while line = input.gets
      line.set_encoding("ASCII-8BIT") if line.respond_to?(:set_encoding)

      if line.strip =~ %r{^([A-Z]+) (.+) HTTP/1\.(\d+)$}
        puts "[#{Time.now}] #{line.strip}"
      end
      if line.strip =~ /^Content-Length: (\d+)$/
        content_length = $1.to_i
      end

      output.write(line)
      break if line.strip.empty?
    end

    output.write(input.read(content_length)) if content_length > 0
    output.flush

    # RACK SERVER > SOCKET
    content_length = 0
    connection = nil
    while line = output.gets
      line.set_encoding("ASCII-8BIT") if line.respond_to?(:set_encoding)

      if line.strip =~ /^Content-Length: (\d+)$/
        content_length = $1.to_i
      end
      if line.strip =~ /^Connection: (.+)$/
        connection = $1.strip
      end

      input.write(line)
      break if line.strip.empty?
    end

    if content_length > 0
      input.write(output.read(content_length)) 
    elsif connection == "close"
      begin
        input.write(output.read)
      rescue EOFError
      end
    end
    input.flush

    input.close
    output.close
  end
}
