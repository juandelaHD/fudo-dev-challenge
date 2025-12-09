require 'json'
require 'time'

module ResponseHelpers
  def response(status, body)
    [
      status,
      { 
        'content-type' => 'application/json',
        'cache-control' => 'no-cache'
      },
      [body.to_json]
    ]
  end

  def success_json(data = {}, meta: {})
    { 
      data: data, 
      meta: meta, 
      timestamp: Time.now.utc.iso8601 
    }
  end

  def error_json(status, error, message, env, details: nil)
    payload = {
      status: status,
      error: error,
      message: message,
      path: env['PATH_INFO'],
      timestamp: Time.now.utc.iso8601
    }
    payload[:details] = details if details
    payload
  end

  def error_response(status, error, message, env, details: nil)
    response(status, error_json(status, error, message, env, details: details))
  end
end
