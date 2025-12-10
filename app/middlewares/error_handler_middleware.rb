require 'json'
require 'sequel'
require 'time'
require 'securerandom'
require_relative '../../lib/response_helpers'
require_relative '../../lib/errors'

class ErrorHandlerMiddleware
  include ResponseHelpers

  ERROR_BACKTRACE_LINES = (ENV['ERROR_BACKTRACE_LINES'] || '10').to_i
  ERROR_SEPARATOR = '=' * 80

  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue StandardError => e
    handle_error(e, env)
  end

  private

  def handle_error(error, env)
    path = env['PATH_INFO']
    method = env['REQUEST_METHOD']
    request_id = env['HTTP_X_REQUEST_ID'] || SecureRandom.uuid

    case error
    when Sequel::ValidationFailed, Errors::ValidationError
      details = error.respond_to?(:errors) ? error.errors : nil
      log_handled_error(error, method, path, 422, request_id)
      unprocessable_entity(error.message, details: details, path: path)
    when Sequel::UniqueConstraintViolation, Errors::Conflict
      log_handled_error(error, method, path, 409, request_id)
      conflict('Resource already exists', path: path)
    when Sequel::NoMatchingRow, Errors::NotFound
      log_handled_error(error, method, path, 404, request_id)
      not_found('Resource not found', path: path)
    when Errors::Unauthorized
      message = error.message.to_s.empty? ? 'Authentication required' : error.message
      log_handled_error(error, method, path, 401, request_id)
      unauthorized(message, path: path)
    when ArgumentError
      log_handled_error(error, method, path, 400, request_id)
      bad_request(error.message, path: path)
    when NoMethodError, NameError, TypeError
      log_unhandled_error(error, method, path, request_id)
      internal_server_error('Internal error: invalid operation', path: path)
    else
      log_unhandled_error(error, method, path, request_id)
      internal_server_error('An unexpected error occurred', path: path)
    end
  end

  def log_handled_error(error, method, path, status, request_id)
    $stdout.puts "[#{Time.now.utc.iso8601}] [#{request_id}] #{method} #{path} - #{status} #{error.class}: #{error.message}"
    $stdout.flush
  end

  def log_unhandled_error(error, method, path, request_id)
    $stderr.puts ERROR_SEPARATOR
    $stderr.puts "[UNHANDLED ERROR] #{Time.now.utc.iso8601}"
    $stderr.puts "Request ID: #{request_id}"
    $stderr.puts "#{method} #{path}"
    $stderr.puts "Error Class: #{error.class}"
    $stderr.puts "Error Message: #{error.message}"
    $stderr.puts "Backtrace:"
    $stderr.puts error.backtrace.first(ERROR_BACKTRACE_LINES).map { |line| "  #{line}" }.join("\n")
    $stderr.puts ERROR_SEPARATOR
    $stderr.flush
  end
end