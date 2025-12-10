# frozen_string_literal: true

require_relative '../test_helper'

class ProductsIntegrationTest < Minitest::Test
  include TestHelpers

  # GET /products tests
  def test_list_products_requires_authentication
    get api('/products')
    assert_unauthorized
  end

  def test_list_products_returns_data_with_pagination
    user = create_test_user(email: "#{SecureRandom.hex(4)}@example.com")
    create_test_product(name: "Product #{SecureRandom.hex(4)}", user: user)
    
    token = get_auth_token(user)
    get api('/products'), {}, auth_headers(token)

    assert_equal 200, last_response.status
    data = json_response
    assert_includes data, 'data'
    assert_kind_of Array, data['data']
  end

  def test_list_products_filters_by_type_local
    user = create_test_user(email: "#{SecureRandom.hex(4)}@example.com")
    create_test_product(name: "Local #{SecureRandom.hex(4)}", user: user)
    
    token = get_auth_token(user)
    get api('/products?type=local'), {}, auth_headers(token)

    assert_equal 200, last_response.status
    data = json_response
    data['data'].each do |product|
      assert_nil product['external_id']
    end
  end

  # POST /products tests (sync)
  def test_create_product_requires_authentication
    post api('/products'), { name: 'Test' }.to_json,
      { 'CONTENT_TYPE' => 'application/json' }
    
    assert_unauthorized
  end

  def test_create_product_synchronously_returns_201
    user = create_test_user(email: "#{SecureRandom.hex(4)}@example.com")
    token = get_auth_token(user)
    
    post api('/products'), {
      name: "Product #{SecureRandom.hex(4)}",
      description: 'A great product'
    }.to_json, auth_headers(token).merge({ 'CONTENT_TYPE' => 'application/json' })

    assert_equal 201, last_response.status
    data = json_response
    assert_includes data, 'data'
    refute_nil data['data']['id']
  end

  def test_create_product_validates_name_presence
    user = create_test_user(email: "#{SecureRandom.hex(4)}@example.com")
    token = get_auth_token(user)
    
    post api('/products'), {
      description: 'Only description'
    }.to_json, auth_headers(token).merge({ 'CONTENT_TYPE' => 'application/json' })

    assert_equal 422, last_response.status
  end

  def test_create_product_validates_name_length
    user = create_test_user(email: "#{SecureRandom.hex(4)}@example.com")
    token = get_auth_token(user)
    long_name = 'A' * 300
    
    post api('/products'), {
      name: long_name
    }.to_json, auth_headers(token).merge({ 'CONTENT_TYPE' => 'application/json' })

    assert_equal 422, last_response.status
  end

  # POST /products tests (async)
  def test_create_product_asynchronously_returns_202
    user = create_test_user(email: "#{SecureRandom.hex(4)}@example.com")
    token = get_auth_token(user)
    
    post api('/products?async=true'), {
      name: "Async #{SecureRandom.hex(4)}",
      description: 'Created asynchronously'
    }.to_json, auth_headers(token).merge({ 'CONTENT_TYPE' => 'application/json' })

    assert_equal 202, last_response.status
    data = json_response
    assert_includes data, 'data'
    assert_includes data['data'], 'job_id'
  end
end
