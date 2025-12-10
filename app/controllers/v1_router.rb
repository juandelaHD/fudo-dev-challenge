# frozen_string_literal: true

require_relative '../../lib/response_helpers'
require_relative 'auth_controller'
require_relative 'products_controller'
require_relative 'jobs_controller'

class V1Router
  include ResponseHelpers

  def call(env)
    request = Rack::Request.new(env)
    path = request.path_info
    method = request.request_method

    if path == '/' && method == 'OPTIONS'
      return api_discovery
    end

    case path
    when '/'
      method_not_allowed('Use OPTIONS method for API discovery', path: path)
    when '/auth/register'
      return method_not_allowed('The HTTP method is not allowed for this endpoint', path: path) unless method == 'POST'
      AuthController.new(request).register
    when '/auth/login'
      return method_not_allowed('The HTTP method is not allowed for this endpoint', path: path) unless method == 'POST'
      AuthController.new(request).login
    when '/products'
      case method
      when 'GET'
        ProductsController.new(request).index
      when 'POST'
        ProductsController.new(request).create
      else
        method_not_allowed('Only GET and POST methods are allowed', path: path)
      end
    when '/jobs'
      return method_not_allowed('Only GET method is allowed', path: path) unless method == 'GET'
      JobsController.new(request).index
    when %r{^/jobs/([a-f0-9-]+)$}
      return method_not_allowed('Only GET method is allowed', path: path) unless method == 'GET'
      match_data = path.match(%r{^/jobs/([a-f0-9-]+)$})
      job_id = match_data[1] if match_data
      request.params['id'] = job_id
      JobsController.new(request).show
    else
      not_found(path: path)
    end
  rescue ArgumentError => e
    bad_request(e.message, path: path)
  end

  private

  def api_discovery
    endpoints = [
      {
        path: '/v1/auth/register',
        method: 'POST',
        description: 'Register a new user account',
        auth_required: false
      },
      {
        path: '/v1/auth/login',
        method: 'POST',
        description: 'Authenticate user and obtain JWT token',
        auth_required: false
      },
      {
        path: '/v1/products',
        method: 'GET',
        description: 'List all products with pagination',
        auth_required: true
      },
      {
        path: '/v1/products',
        method: 'POST',
        description: 'Create a new product (use async=true for async processing)',
        auth_required: true
      },
      {
        path: '/v1/jobs',
        method: 'GET',
        description: 'List async jobs',
        auth_required: true
      },
      {
        path: '/v1/jobs/:id',
        method: 'GET',
        description: 'Get async job status',
        auth_required: true
      }
    ]

    data = {
      api: 'Fudo Products API',
      version: 'v1',
      endpoints: endpoints
    }

    extra = { 'allow' => 'OPTIONS', 'cache-control' => 'no-cache' }
    success_response(200, data, extra_headers: extra)
  end
end
