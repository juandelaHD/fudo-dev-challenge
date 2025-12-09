require 'json'
require 'sequel'
require 'time'
require_relative '../../lib/response_helpers'

class ErrorHandlerMiddleware
  include ResponseHelpers

  ERROR_BACKTRACE_LINES = (ENV['ERROR_BACKTRACE_LINES'] || '10').to_i

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
    case error
    when Sequel::ValidationFailed, Errors::ValidationError
      details = error.respond_to?(:errors) ? error.errors : nil
      error_response(422, 'Unprocessable Entity', error.message, env, details: details)
    when Sequel::UniqueConstraintViolation, Errors::Conflict
      error_response(409, 'Conflict', 'Resource already exists', env)
    when Sequel::NoMatchingRow, Errors::NotFound
      error_response(404, 'Not Found', 'Resource not found', env)
    when Errors::Unauthorized
      error_response(401, 'Unauthorized', error.message.empty? ? 'Authentication required' : error.message, env)
    when ArgumentError
      error_response(400, 'Bad Request', error.message, env)
    else
      log_error(error)
      error_response(500, 'Internal Server Error', 'An unexpected error occurred', env)
    end
  end

  def log_error(error)
    warn "[ERROR] #{error.class}: #{error.message}"
    warn error.backtrace.first(ERROR_BACKTRACE_LINES).join("\n") if ENV['RACK_ENV'] == 'development'
  end
end