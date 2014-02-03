run(lambda do |env|
  raise StandardError, "crash on request"
end)
