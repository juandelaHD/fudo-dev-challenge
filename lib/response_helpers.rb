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

  def success_json(data = {}, meta: {}, links: nil)
    default_meta = {
      request_id: generate_request_id,
      timestamp: Time.now.utc.iso8601
    }
    
    response = { 
      data: data, 
      meta: default_meta.merge(meta)
    }
    response[:links] = links if links
    response
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

  def success_response(status, data, meta: {}, links: nil, extra_headers: {})
    body = success_json(data, meta: meta, links: links)
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

  def ok(data, meta: {}, links: nil)
    success_response(200, data, meta: meta, links: links)
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

  def api_base_path
    prefix = (ENV['API_PREFIX'] || '/v1').to_s
    return '' if prefix == '/'
    prefix.start_with?('/') ? prefix : "/#{prefix}"
  end

  def resource_location(resource, id = nil)
    resource_str = resource.to_s
    base = api_base_path
    path = base.empty? ? "/#{resource_str}" : "#{base}/#{resource_str}"
    path += "/#{id}" if id
    path
  end

  def build_pagination_meta(resource, page, size, total_pages, total_items)
    meta = {
      page: page,
      size: size,
      total_pages: total_pages,
      total_items: total_items
    }
    meta
  end

  def build_pagination_links(resource, page, size, total_pages)
    links = {}
    base_url = resource_location(resource)
    
    links[:self] = "#{base_url}?page=#{page}&size=#{size}"
    
    if page < total_pages
      next_page = page + 1
      links[:next] = "#{base_url}?page=#{next_page}&size=#{size}"
    end
    
    if page > 1
      prev_page = page - 1
      links[:prev] = "#{base_url}?page=#{prev_page}&size=#{size}"
    end
    
    links[:first] = "#{base_url}?page=1&size=#{size}"
    links[:last] = "#{base_url}?page=#{total_pages}&size=#{size}" if total_pages > 0
    
    links
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
