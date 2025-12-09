Sequel.migration do
  up do
    create_table(:users) do
      primary_key :id
      
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
    puts 'Dropped users table'
  end
end
