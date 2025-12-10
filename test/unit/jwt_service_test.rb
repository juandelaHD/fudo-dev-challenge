# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../app/services/jwt_service'
require 'jwt'

class JwtServiceTest < Minitest::Test
  def test_encode_creates_valid_token
    payload = { user_id: 'test-user-123' }
    token = JwtService.encode(payload)
    
    assert_kind_of String, token
    refute_empty token
  end

  def test_decode_returns_original_payload
    payload = { user_id: 'test-user-456' }
    token = JwtService.encode(payload)
    
    decoded = JwtService.decode(token)
    assert_equal 'test-user-456', decoded[:user_id]
  end

  def test_decode_handles_expired_token
    payload = { user_id: '123', iat: Time.now.to_i, exp: Time.now.to_i - 3600 }
    expired_token = JWT.encode(payload, ENV['JWT_SECRET'], 'HS256')
    
    assert_raises(JwtService::TokenExpiredError) do
      JwtService.decode(expired_token)
    end
  end

  def test_decode_handles_invalid_token
    assert_raises(JwtService::TokenInvalidError) do
      JwtService.decode('invalid.token.here')
    end
  end

  def test_token_contains_standard_claims
    payload = { user_id: 'user-789' }
    token = JwtService.encode(payload)
    decoded = JwtService.decode(token)
    
    assert_includes decoded, :iat
    assert_includes decoded, :exp
  end
end
