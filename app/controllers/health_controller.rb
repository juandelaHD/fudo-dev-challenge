require_relative 'base_controller'
require_relative '../../config/database'

class HealthController < BaseController
  def index
    db_healthy = Database.healthy?

    status = db_healthy ? 200 : 503
    
    health_data = {
      status: db_healthy ? 'healthy' : 'unhealthy',
      database: {
        connected: db_healthy,
        info: db_healthy ? Database.connection_info : nil
      }
    }
    
    if db_healthy
      ok(health_data)
    else
      response(status, success_json(health_data))
    end
  end
end
