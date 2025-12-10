# frozen_string_literal: true

require 'minitest/autorun'
require 'rack/test'
require 'json'
require 'database_cleaner/sequel'

require_relative '../config/database'
require_relative '../app/application'
require_relative '../app/models/user'
require_relative '../app/models/product'
require_relative '../app/models/sync_log'
require_relative '../app/services/jwt_service'
require_relative '../app/services/user_authenticator'
require_relative '../app/validators/register_validator'
require_relative '../app/validators/product_validator'

# The database used in tests (local PostgreSQL) is cleaned before each test run
DatabaseCleaner[:sequel].strategy = :truncation

API_PREFIX = ENV['API_PREFIX'] || '/v1'
DEFAULT_TEST_EMAIL = 'test@example.com'
DEFAULT_TEST_PASSWORD = 'Password123!'
NEW_USER_EMAIL = 'newuser@example.com'
EXISTING_EMAIL = 'existing@example.com'
LOGIN_EMAIL = 'login@example.com'
USER1_EMAIL = 'user1@example.com'
USER2_EMAIL = 'user2@example.com'

def api(path)
  p = path.start_with?('/') ? path : "/#{path}"
  "#{API_PREFIX}#{p}"
end

module TestHelpers
  include Rack::Test::Methods

  def app
    Application.app
  end

  def setup
    DatabaseCleaner[:sequel].start
    @test_user = nil
    @auth_token = nil
  end

  def teardown
    DatabaseCleaner[:sequel].clean
  end

  def create_test_user(email: 'test@example.com', password: 'Password123!')
    User.create(
      email: email,
      password_hash: BCrypt::Password.create(password)
    )
  end

  def get_auth_token(user = nil)
    unless user
      user = create_test_user(email: "test-#{SecureRandom.hex(4)}@example.com")
    end
    token = JwtService.encode(user_id: user.id)
    token
  end

  def auth_headers(token = nil)
    token ||= get_auth_token
    { 'HTTP_AUTHORIZATION' => "Bearer #{token}" }
  end

  def json_response
    JSON.parse(last_response.body)
  end

  def create_test_product(name: 'Test Product', user: nil, external_id: nil)
    user ||= create_test_user
    Product.create(
      name: name,
      description: 'Test description',
      user_id: user.id,
      external_id: external_id
    )
  end

  def assert_json_response
    assert_equal 'application/json', last_response.content_type
  end

  def assert_success_response(expected_status = 200)
    assert_equal expected_status, last_response.status
    assert_json_response
  end

  def assert_error_response(expected_status, error_message = nil)
    assert_equal expected_status, last_response.status
    assert_json_response
    
    data = json_response
    assert_includes data, 'error'
    assert_equal error_message, data['error'] if error_message
  end

  def assert_unauthorized
    assert_equal 401, last_response.status
    assert_json_response
    data = json_response
    assert_includes data, 'message'
    assert_includes ['Unauthorized', 'Missing authorization token'], data['message']
  end

  def assert_validation_error(field = nil)
    assert_equal 422, last_response.status
    assert_json_response
    
    data = json_response
    assert_includes data, 'errors'
    assert_kind_of Array, data['errors']
    
    if field
      assert data['errors'].any? { |e| e.include?(field) }, 
             "Expected validation error for field '#{field}'"
    end
  end
end
