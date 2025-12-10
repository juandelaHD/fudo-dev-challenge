# frozen_string_literal: true

require_relative '../../config/database'

class HealthService
  class HealthCheckError < StandardError; end

  def self.check_health
    db_healthy = check_database_health
    
    {
      status: db_healthy ? 'healthy' : 'unhealthy',
      http_status: db_healthy ? 200 : 503,
      checks: {
        database: db_check_details(db_healthy)
      },
      metadata: {
        environment: ENV['RACK_ENV'] || 'development',
        timestamp: Time.now.utc.iso8601
      }
    }
  end

  def self.check_database_health
    Database.healthy?
  rescue => e
    warn "Database health check failed: #{e.message}"
    false
  end

  def self.db_check_details(is_healthy)
    {
      status: is_healthy ? 'up' : 'down',
      response_time_ms: measure_database_response_time,
      details: is_healthy ? safe_connection_info : nil
    }
  end

  def self.measure_database_response_time
    start = Time.now
    Database.healthy?
    ((Time.now - start) * 1000).round(2)
  rescue => e
    warn "Failed to measure database response time: #{e.message}"
    nil
  end

  def self.safe_connection_info
    Database.connection_info
  rescue => e
    warn "Failed to retrieve connection info: #{e.message}"
    { error: 'Unable to retrieve connection information' }
  end

  def self.ready?
    check_database_health
  end

  def self.alive?
    true
  end
end
