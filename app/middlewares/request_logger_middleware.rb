# frozen_string_literal: true

require 'securerandom'
require 'time'

class RequestLoggerMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request_id = SecureRandom.uuid
    method = env['REQUEST_METHOD']
    path = env['PATH_INFO']
    start_time = Time.now

    env['HTTP_X_REQUEST_ID'] = request_id

    $stdout.puts "[#{start_time.utc.iso8601}] [#{request_id}] --> #{method} #{path}"
    $stdout.flush

    status, headers, body = @app.call(env)

    duration_ms = ((Time.now - start_time) * 1000).round(2)

    $stdout.puts "[#{Time.now.utc.iso8601}] [#{request_id}] <-- #{method} #{path} - #{status} (#{duration_ms}ms)"
    $stdout.flush

    [status, headers, body]
  end
end
