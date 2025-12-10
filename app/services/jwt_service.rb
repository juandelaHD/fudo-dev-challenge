# frozen_string_literal: true

require 'jwt'
require 'time'

class JwtService
  ALGORITHM = 'HS256'
  DEFAULT_EXPIRATION_MINUTES = 30
  EXPIRATION = begin
    raw = ENV['JWT_EXPIRATION']
    default_seconds = DEFAULT_EXPIRATION_MINUTES * 60

    if raw.nil? || raw.to_s.strip.empty?
      $stderr.puts "[#{Time.now.utc.iso8601}] WARNING: JWT_EXPIRATION not set. Using default #{DEFAULT_EXPIRATION_MINUTES} minutes (#{default_seconds} seconds)."
      default_seconds
    else
      minutes = raw.to_i
      if minutes > 0
        minutes * 60
      else
        $stderr.puts "[#{Time.now.utc.iso8601}] WARNING: JWT_EXPIRATION has invalid value '#{raw}'. Using default #{DEFAULT_MINUTES} minutes (#{default_seconds} seconds)."
        default_seconds
      end
    end
  end

  class << self
    def encode(payload)
      payload = payload.dup
      payload[:iat] = Time.now.to_i
      payload[:exp] = Time.now.to_i + EXPIRATION
      
      JWT.encode(payload, secret_key, ALGORITHM)
    end

    def decode(token)
      decoded = JWT.decode(token, secret_key, true, algorithm: ALGORITHM)
      decoded.first.transform_keys(&:to_sym)
    rescue JWT::ExpiredSignature
      raise TokenExpiredError, 'Token has expired'
    rescue JWT::DecodeError => e
      raise TokenInvalidError, "Invalid token: #{e.message}"
    end

    def valid?(token)
      decode(token)
      true
    rescue TokenExpiredError, TokenInvalidError
      false
    end

    private

    def secret_key
      key = ENV['JWT_SECRET']
      raise 'JWT_SECRET not configured' if key.nil? || key.empty?
      raise 'JWT_SECRET must be at least 32 characters' if key.length < 32
      key
    end
  end

  class TokenExpiredError < StandardError; end
  class TokenInvalidError < StandardError; end
end
