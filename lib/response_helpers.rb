require 'json'
require 'time'
require 'securerandom'

module ResponseHelpers
  def response(status, body)
    [
      status,
      { 
        'content-type' => 'application/json',
        'cache-control' => 'no-cache',
        'x-request-id' => generate_request_id
      },
      [body.to_json]
    ]
  end

  def success_json(data = {}, meta: {})
    default_meta = {
      request_id: generate_request_id,
      timestamp: Time.now.utc.iso8601
    }
    
    { 
      data: data, 
      meta: default_meta.merge(meta)
    }
  end

  def error_json(status, error, message, path: nil, details: nil)
    payload = {
      status: status,
      error: error,
      message: message,
      request_id: generate_request_id,
      timestamp: Time.now.utc.iso8601
    }
    payload[:path] = path if path
    payload[:details] = details if details
    payload
  end

  def success_response(status, data, meta: {}, extra_headers: {})
    body = success_json(data, meta: meta)
    request_id = body[:meta][:request_id]

    normalized_extra = extra_headers.transform_keys { |k| k.to_s.downcase }

    headers = {
      'content-type' => 'application/json',
      'x-request-id' => request_id
    }.merge(normalized_extra)

    [status, headers, [body.to_json]]
  end

  def error_response(status, message, path: nil, details: nil, extra_headers: {})
    error_name = status_to_error_name(status)
    body = error_json(status, error_name, message, path: path, details: details)
    request_id = body[:request_id]

    normalized_extra = extra_headers.transform_keys { |k| k.to_s.downcase }

    headers = {
      'content-type' => 'application/json',
      'x-request-id' => request_id
    }.merge(normalized_extra)

    [status, headers, [body.to_json]]
  end

  def ok(data, meta: {})
    success_response(200, data, meta: meta)
  end

  def created(data, meta: {})
    success_response(201, data, meta: meta)
  end

  def bad_request(message, details: nil, path: nil)
    error_response(400, message, path: path, details: details)
  end

  def unauthorized(message = 'Unauthorized', path: nil)
    error_response(401, message, path: path)
  end

  def not_found(message = 'Resource not found', path: nil)
    error_response(404, message, path: path)
  end

  def conflict(message = 'Resource already exists', path: nil)
    error_response(409, message, path: path)
  end

  def unprocessable_entity(message, details: nil, path: nil)
    error_response(422, message, path: path, details: details)
  end

  def method_not_allowed(message = 'Method not allowed', path: nil)
    error_response(405, message, path: path)
  end

  def internal_server_error(message = 'An unexpected internal server error occurred. Please try again later or contact support if the issue persists.', path: nil)
    error_response(500, message, path: path)
  end

  private

  def generate_request_id
    if defined?(@request) && @request && @request.respond_to?(:env)
      return @request.env['HTTP_X_REQUEST_ID'] if @request.env['HTTP_X_REQUEST_ID']
    end
    
    @request_id ||= SecureRandom.uuid
  end

  def status_to_error_name(status)
    case status
    when 400 then 'Bad Request'
    when 401 then 'Unauthorized'
    when 403 then 'Forbidden'
    when 404 then 'Not Found'
    when 405 then 'Method Not Allowed'
    when 409 then 'Conflict'
    when 422 then 'Unprocessable Entity'
    when 500 then 'Internal Server Error'
    when 503 then 'Service Unavailable'
    else 'Error'
    end
  end
end
