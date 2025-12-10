# frozen_string_literal: true

require_relative '../test_helper'

class UserAuthenticatorTest < Minitest::Test
  def test_authenticate_with_valid_credentials
    user = User.create(
      email: 'auth@example.com',
      password_hash: BCrypt::Password.create('Password123!')
    )
    
    result = UserAuthenticator.new('auth@example.com', 'Password123!').call
    
    assert_includes result, :user
    assert_includes result, :token
    assert_equal user.id, result[:user][:id]
  ensure
    user&.delete
  end

  def test_authenticate_with_invalid_email
    assert_raises(UserAuthenticator::AuthenticationError) do
      UserAuthenticator.new('nonexistent@example.com', 'Password123!').call
    end
  end

  def test_authenticate_with_wrong_password
    user = User.create(
      email: "wrong#{SecureRandom.hex(4)}@example.com",
      password_hash: BCrypt::Password.create('CorrectPassword123!')
    )
    
    assert_raises(UserAuthenticator::AuthenticationError) do
      UserAuthenticator.new(user.email, 'WrongPassword123!').call
    end
  ensure
    user&.delete
  end

  def test_authenticate_with_nil_email
    assert_raises(UserAuthenticator::AuthenticationError) do
      UserAuthenticator.new(nil, 'Password123!').call
    end
  end
end
