Sequel.migration do
  up do
    create_table(:product_sync_logs) do
      column :id, :uuid, primary_key: true, default: Sequel.function(:gen_random_uuid)
      
      foreign_key :product_id, :products, type: :uuid, null: false, on_delete: :cascade
      foreign_key :sync_log_id, :sync_logs, type: :uuid, null: false, on_delete: :cascade
      
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      
      index :product_id, name: :idx_product_sync_logs_product_id
      index :sync_log_id, name: :idx_product_sync_logs_sync_log_id
      index [:product_id, :sync_log_id], unique: true, name: :idx_product_sync_logs_unique
    end
    
    puts 'Created product_sync_logs table'
  end

  down do
    drop_table(:product_sync_logs)
    puts 'Dropped product_sync_logs table'
  end
end
