Sequel.migration do
  up do
    run 'CREATE EXTENSION IF NOT EXISTS "pgcrypto"'
    
    create_table(:users) do
      column :id, :uuid, primary_key: true, default: Sequel.function(:gen_random_uuid)
      
      String :email, null: false, unique: true, size: 255
      String :password_hash, null: false, size: 255
      
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      
      index :email, name: :idx_users_email
    end
    
    puts 'Created users table'
  end

  down do
    drop_table(:users)
    run 'DROP EXTENSION IF EXISTS "pgcrypto"'
    puts 'Dropped users table'
  end
end
