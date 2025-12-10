# frozen_string_literal: true

require_relative '../test_helper'

class HealthIntegrationTest < Minitest::Test
  include TestHelpers

  def test_health_check_returns_healthy_status
    get '/health'

    assert_equal 200, last_response.status
    data = json_response
    assert_includes data, 'data'
    assert_equal 'healthy', data['data']['status']
  end

  def test_health_check_includes_database_check
    get '/health'

    assert_equal 200, last_response.status
    data = json_response
    assert_includes data['data'], 'checks'
    assert_includes data['data']['checks'], 'database'
    assert_equal 'up', data['data']['checks']['database']['status']
  end

  def test_health_check_does_not_require_authentication
    get '/health'
    assert_equal 200, last_response.status
  end
end
