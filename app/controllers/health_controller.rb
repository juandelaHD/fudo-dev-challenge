require_relative 'base_controller'
require_relative '../../config/database'

class HealthController < BaseController
  def index
    db_healthy = Database.healthy?

    status = db_healthy ? 200 : 503
    
    health_data = {
      status: db_healthy ? 'healthy' : 'unhealthy',
      checks: {
        database: {
          status: db_healthy ? 'up' : 'down',
          response_time_ms: measure_db_response_time,
          details: db_healthy ? Database.connection_info : nil
        }
      }
    }

    meta = {
      version: 'v1',
      environment: ENV['RACK_ENV'] || 'development'
    }
    
    [status, {
      'content-type' => 'application/json',
      'x-request-id' => generate_request_id,
      'cache-control' => 'no-cache, no-store, must-revalidate'
    }, [success_json(health_data, meta: meta).to_json]]
  end

  private

  def measure_db_response_time
    start = Time.now
    Database.healthy?
    ((Time.now - start) * 1000).round(2)
  rescue
    nil
  end
end
