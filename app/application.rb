require 'rack'
require 'json'
require_relative '../lib/response_helpers'
require_relative 'controllers/health_controller'

class Application
  include ResponseHelpers

  def call(env)
    request = Rack::Request.new(env)
    
    case [request.request_method, request.path_info]
    when ['GET', '/health']
      HealthController.new(request).index
    else
      not_found(env)
    end
  end

  private

  def not_found(env)
    error_response(404, 'Not Found', 'Resource not found', env)
  end
end
