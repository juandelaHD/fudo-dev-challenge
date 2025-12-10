# frozen_string_literal: true

require_relative '../test_helper'

class RegisterValidatorTest < Minitest::Test
  def test_validates_valid_data
    result = RegisterValidator.call(email: 'test@example.com', password: 'Pass123!')
    
    assert result[:success]
    assert_equal 'test@example.com', result[:data][:email]
  end

  def test_rejects_missing_email
    result = RegisterValidator.call(password: 'Pass123!')
    
    refute result[:success]
    assert_includes result[:errors], :email
  end

  def test_rejects_invalid_email_format
    ['invalid', 'test@', '@example.com', 'test @example.com'].each do |invalid_email|
      result = RegisterValidator.call(email: invalid_email, password: 'Pass123!')
      refute result[:success], "Expected #{invalid_email} to be invalid"
    end
  end

  def test_accepts_valid_email_formats
    ['test@example.com', 'user+tag@domain.co', 'name.surname@company.org'].each do |valid_email|
      result = RegisterValidator.call(email: valid_email, password: 'Pass123!')
      assert result[:success], "Expected #{valid_email} to be valid"
    end
  end

  def test_rejects_short_password
    result = RegisterValidator.call(email: 'test@example.com', password: 'ab')
    
    refute result[:success]
    assert_includes result[:errors], :password
  end

  def test_rejects_long_password
    long_password = 'a' * 51
    result = RegisterValidator.call(email: 'test@example.com', password: long_password)
    
    refute result[:success]
    assert_includes result[:errors], :password
  end

  def test_accepts_strong_password
    ['Pass123!', 'Secure@2024', 'MyP@ssw0rd'].each do |password|
      result = RegisterValidator.call(email: 'test@example.com', password: password)
      assert result[:success], "Expected #{password} to be valid"
    end
  end
end
