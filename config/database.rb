require 'sequel'

module Database
  def self.connection
    @connection ||= begin
      rack_env = ENV['RACK_ENV'] || 'development'
      
      database_url = if rack_env == 'production'
        ENV['DATABASE_URL']
      else
        ENV['DEV_DATABASE_URL']
      end

      if database_url.nil? || database_url.strip.empty?
        raise "Database URL is not set. Please configure #{var_name} in your .env file"
      end

      puts "[Database] Environment: #{rack_env}"
      puts "[Database] Connecting to: #{database_url.gsub(/:[^:@]+@/, ':****@')}"
      
      db = Sequel.connect(
        database_url,
        max_connections: 10,
        pool_timeout: 5,
        test: false,
        connect_timeout: 3
      )
      
      Sequel.application_timezone = :utc
      Sequel.database_timezone = :utc
      Sequel.typecast_timezone = :utc
      
      db.run("SET TIME ZONE 'UTC'")
      
      db.extension :pg_json
      db
    end
  end

  def self.healthy?
    connection.test_connection
    true
  rescue => e
    warn "Database health check failed: #{e.message}"
    false
  end
  
  def self.connection_info
    {
      adapter: connection.adapter_scheme,
      database: connection.opts[:database],
      host: connection.opts[:host],
      port: connection.opts[:port]
    }
  rescue => e
    { error: e.message }
  end
end

DB = Database.connection
