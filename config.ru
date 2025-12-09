require 'dotenv/load'
require_relative 'config/database'
require_relative 'lib/response_helpers'
require_relative 'lib/errors'
require_relative 'app/middlewares/error_handler_middleware'
require_relative 'app/application'

use ErrorHandlerMiddleware
run Application.new
