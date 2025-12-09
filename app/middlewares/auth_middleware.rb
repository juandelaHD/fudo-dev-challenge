# frozen_string_literal: true

require_relative '../services/jwt_service'
require_relative '../../lib/response_helpers'

class AuthMiddleware
  include ResponseHelpers

  EXCLUDED_PATHS = [
    '/',
    '/v1',
    '/v1/',
    '/health',
    '/v1/auth/login',
    '/v1/auth/register'
  ].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    return @app.call(env) if excluded_path?(request.path_info)

    token = extract_token(request)
    return unauthorized('Missing authorization token') unless token

    payload = verify_token(token)
    return unauthorized('Invalid or expired token') unless payload

    env['user_id'] = payload[:user_id]

    @app.call(env)
  end

  private

  def excluded_path?(path)
    EXCLUDED_PATHS.any? { |excluded| path.start_with?(excluded) }
  end

  def extract_token(request)
    auth_header = request.get_header('HTTP_AUTHORIZATION')
    return nil unless auth_header

    parts = auth_header.split(' ')
    return nil unless parts.length == 2 && parts[0] == 'Bearer'

    parts[1]
  end

  def verify_token(token)
    JwtService.decode(token)
  rescue JwtService::TokenExpiredError, JwtService::TokenInvalidError
    nil
  end
end
