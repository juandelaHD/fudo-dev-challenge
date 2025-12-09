require 'rack'
require 'json'
require 'dotenv/load'
require_relative '../config/database'
require_relative '../lib/response_helpers'
require_relative 'middlewares/request_logger_middleware'
require_relative 'middlewares/error_handler_middleware'
require_relative 'middlewares/auth_middleware'
require_relative 'controllers/v1_router'
require_relative 'controllers/health_controller'

class Application
  def self.app
    Rack::Builder.new do
      use Rack::ContentType, 'application/json'
      use Rack::Deflater
      use RequestLoggerMiddleware
      use ErrorHandlerMiddleware
      use AuthMiddleware

      map '/health' do
        run lambda { |env|
          request = Rack::Request.new(env)
          HealthController.new(request).index
        }
      end

      map '/v1' do
        run V1Router.new
      end

      map '/' do
        run lambda { |_env|
          helper = Object.new.extend(ResponseHelpers)
          data = {
            message: 'Fudo Products API',
            version: 'v1',
          }
          helper.ok(data)
        }
      end
    end
  end
end
