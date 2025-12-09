# frozen_string_literal: true

require_relative '../models/user'
require_relative './jwt_service'

class UserAuthenticator
  class AuthenticationError < StandardError; end

  def initialize(email, password)
    @email = email
    @password = password
  end

  def call
    user = find_user
    verify_password!(user)
    generate_response(user)
  end

  private

  def find_user
    user = User.where(email: @email).first
    raise AuthenticationError, 'Invalid email or password' unless user
    user
  end

  def verify_password!(user)
    authenticated = user.authenticate(@password)
    raise AuthenticationError, 'Invalid email or password' unless authenticated
  end

  def generate_response(user)
    token = JwtService.encode(user_id: user.id)
    exp_time = Time.now + JwtService::EXPIRATION
    token_info = {
      token_id: token,
      type: 'Bearer',
      expires_in: JwtService::EXPIRATION,
      expires_at: exp_time.iso8601
    }

    {
      user: user.to_hash,
      token: token_info
    }
  end
end
