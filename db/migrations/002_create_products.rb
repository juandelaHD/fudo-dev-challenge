Sequel.migration do
  up do
    create_table(:products) do
      primary_key :id
      
      String :name, null: false, unique: true, size: 255
      String :description, text: true
      String :external_id, unique: true, size: 255
      foreign_key :user_id, :users, null: true, on_delete: :set_null
      
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      
      index :name, name: :idx_products_name
      index :external_id, name: :idx_products_external_id, 
            where: 'external_id IS NOT NULL'
      index :created_at, name: :idx_products_created_at
      index :user_id, name: :idx_products_user_id
    end
    
    puts 'Created products table'
  end

  down do
    drop_table(:products)
    puts 'Dropped products table'
  end
end
