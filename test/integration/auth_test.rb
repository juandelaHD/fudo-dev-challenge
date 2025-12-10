# frozen_string_literal: true

require_relative '../test_helper'

class AuthIntegrationTest < Minitest::Test
  include TestHelpers

  # POST /auth/register tests
  def test_register_creates_user_with_valid_data
    post api('/auth/register'), {
      email: NEW_USER_EMAIL,
      password: 'SecurePass123!'
    }.to_json, { 'CONTENT_TYPE' => 'application/json' }

    assert_equal 201, last_response.status
    data = json_response
    assert_includes data, 'data'
    assert_equal NEW_USER_EMAIL, data['data']['user']['email']
    assert_includes data['data'], 'token'
  end

  def test_register_rejects_duplicate_email
    create_test_user(email: EXISTING_EMAIL)

    post api('/auth/register'), {
      email: EXISTING_EMAIL,
      password: 'AnotherPass123!'
    }.to_json, { 'CONTENT_TYPE' => 'application/json' }

    assert_equal 422, last_response.status
  end

  def test_register_validates_email_format
    post api('/auth/register'), {
      email: 'invalid-email',
      password: 'ValidPass123!'
    }.to_json, { 'CONTENT_TYPE' => 'application/json' }

    assert_equal 400, last_response.status
    data = json_response
    assert_includes data, 'details'
  end

  def test_register_requires_all_fields
    post api('/auth/register'), {}.to_json, 
      { 'CONTENT_TYPE' => 'application/json' }

    assert_equal 400, last_response.status
  end

  # POST /auth/login tests
  def test_login_authenticates_with_valid_credentials
    create_test_user(email: LOGIN_EMAIL, password: 'MyPassword123!')

    post api('/auth/login'), {
      email: LOGIN_EMAIL,
      password: 'MyPassword123!'
    }.to_json, { 'CONTENT_TYPE' => 'application/json' }

    assert_equal 200, last_response.status
    data = json_response
    assert_includes data, 'data'
    assert_equal LOGIN_EMAIL, data['data']['user']['email']
    assert_includes data['data'], 'token'
  end

  def test_login_rejects_invalid_credentials
    create_test_user(email: DEFAULT_TEST_EMAIL, password: 'CorrectPass123!')

    post api('/auth/login'), {
      email: DEFAULT_TEST_EMAIL,
      password: 'WrongPassword123!'
    }.to_json, { 'CONTENT_TYPE' => 'application/json' }

    assert_equal 401, last_response.status
    data = json_response
    assert_includes data['message'], 'password'
  end

  def test_login_rejects_nonexistent_user
    post api('/auth/login'), {
      email: 'nonexistent@example.com',
      password: 'SomePassword123!'
    }.to_json, { 'CONTENT_TYPE' => 'application/json' }

    assert_equal 401, last_response.status
  end

  def test_login_requires_all_fields
    post api('/auth/login'), {}.to_json,
      { 'CONTENT_TYPE' => 'application/json' }

    assert_equal 400, last_response.status
  end
end
