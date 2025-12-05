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

  def ok(data, meta: {})
    response(200, success_json(data, meta: meta))
  end

  def created(data, meta: {})
    response(201, success_json(data, meta: meta))
  end
  
  def parse_json_body
    request.body.rewind
    JSON.parse(request.body.read)
  rescue JSON::ParserError
    raise Errors::ValidationError.new('Invalid JSON')
  end

  def not_found
    raise Errors::NotFound, 'Resource not found'
  end
end
