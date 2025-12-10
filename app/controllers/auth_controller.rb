# frozen_string_literal: true

require_relative 'base_controller'
require_relative '../validators/register_validator'
require_relative '../validators/login_validator'
require_relative '../services/user_register'
require_relative '../services/user_authenticator'
require_relative '../services/jwt_service'

class AuthController < BaseController

  def register
    params = parse_json_body
    validation = RegisterValidator.call(params)

    unless validation[:success]
      return bad_request('Validation failed', details: validation[:errors], path: @request.path_info)
    end

    result = UserRegister.new(
      validation[:data][:email],
      validation[:data][:password]
    ).call

    meta = {
      location: resource_location('users', result[:user][:id])
    }

    created(result, meta: meta)
  rescue UserRegister::RegistrationError => e
    unprocessable_entity(e.message, path: request.path_info)
  
  end

  def login
    params = parse_json_body
    validation = LoginValidator.call(params)

    unless validation[:success]
      return bad_request('Validation failed', details: validation[:errors], path: request.path_info)
    end

    result = UserAuthenticator.new(
      validation[:data][:email],
      validation[:data][:password]
    ).call

    ok(result)
  rescue UserAuthenticator::AuthenticationError => e
    unauthorized(e.message, path: request.path_info)
  end
end
