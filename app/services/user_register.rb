# frozen_string_literal: true

require_relative '../models/user'
require_relative './jwt_service'

class UserRegister
  class RegistrationError < StandardError; end

  def initialize(email, password)
    @email = email
    @password = password
  end

  def call
    validate_email_available!
    user = create_user
    generate_response(user)
  end

  private

  def validate_email_available!
    exists = User.where(email: @email).any?
    raise RegistrationError, 'Email already registered' if exists
  end

  def create_user
    DB.transaction do
      user = User.new(email: @email)
      user.password = @password
      user.save
      user
    end
  rescue Sequel::ValidationFailed => e
    raise RegistrationError, e.message
  rescue Sequel::UniqueConstraintViolation
    raise RegistrationError, 'Email already registered'
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
