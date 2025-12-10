require 'json'
require_relative '../../lib/response_helpers'
require_relative '../../lib/errors'

class BaseController
  include ResponseHelpers
  attr_reader :request, :params

  def initialize(request)
    @request = request
    @params = request.params
  end

  protected

  def parse_json_body
    body = request.body.read
    request.body.rewind if request.body.respond_to?(:rewind)
    return {} if body.nil? || body.empty?

    JSON.parse(body, symbolize_names: true)
  rescue JSON::ParserError
    raise ArgumentError, 'Invalid JSON'
  end

  def current_user_id
    request.env['user_id']
  end

  def not_found!(message = 'Resource not found')
    raise Errors::NotFound, message
  end
end
