Sequel.migration do
  up do
    create_table(:sync_logs) do
      column :id, :uuid, primary_key: true, default: Sequel.function(:gen_random_uuid)
      
      String :sync_type, null: false, size: 50
      String :status, null: false, size: 20
      String :error_message, text: true
      
      DateTime :started_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :completed_at
      
      index :status, name: :idx_sync_logs_status
      index :started_at, name: :idx_sync_logs_started_at
    end
    
    puts 'Created sync_logs table'
  end

  down do
    drop_table(:sync_logs)
    puts 'Dropped sync_logs table'
  end
end
