require_relative 'base_controller'
require_relative '../services/health_service'

class HealthController < BaseController
  def index
    health_result = HealthService.check_health
    
    [health_result[:http_status], {
      'content-type' => 'application/json',
      'x-request-id' => generate_request_id,
      'cache-control' => 'no-cache, no-store, must-revalidate'
    }, [success_json(
      { 
        status: health_result[:status], 
        checks: health_result[:checks] 
      }, 
      meta: health_result[:metadata]
    ).to_json]]
  end
end
