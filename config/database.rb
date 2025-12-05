require 'sequel'

module Database
  def self.connection
    @connection ||= begin
      db = Sequel.connect(
        ENV['DATABASE_URL'],
        max_connections: 10,
        pool_timeout: 5,
        test: false,
        connect_timeout: 3
      )
      db.extension :pg_json
      db
    end
  end

  def self.healthy?
    connection.test_connection
    true
  rescue => e
    puts "Database health check failed: #{e.message}"
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
