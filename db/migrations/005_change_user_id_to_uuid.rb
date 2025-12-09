Sequel.migration do
  up do
    run 'CREATE EXTENSION IF NOT EXISTS "pgcrypto"'
    
    run 'ALTER TABLE products DROP CONSTRAINT IF EXISTS products_user_id_fkey'
    
    run 'ALTER TABLE users ALTER COLUMN id DROP IDENTITY IF EXISTS'
    run 'ALTER TABLE users ALTER COLUMN id DROP DEFAULT'
    run 'ALTER TABLE users ALTER COLUMN id TYPE UUID USING gen_random_uuid()'
    run 'ALTER TABLE users ALTER COLUMN id SET DEFAULT gen_random_uuid()'
    
    run 'UPDATE products SET user_id = NULL WHERE user_id IS NOT NULL'
    run 'ALTER TABLE products ALTER COLUMN user_id TYPE UUID USING NULL'
    
    alter_table(:products) do
      add_foreign_key [:user_id], :users, null: true, on_delete: :set_null
    end
    
    puts 'Changed users.id and products.user_id to UUID'
  end

  down do  
    alter_table(:products) do
      drop_foreign_key :user_id
    end
    
    run 'ALTER TABLE users ALTER COLUMN id DROP DEFAULT'
    run 'ALTER TABLE users ALTER COLUMN id TYPE INTEGER USING NULL'
    run "CREATE SEQUENCE users_id_seq"
    run "ALTER TABLE users ALTER COLUMN id SET DEFAULT nextval('users_id_seq')"
    run "ALTER SEQUENCE users_id_seq OWNED BY users.id"
    
    run 'ALTER TABLE products ALTER COLUMN user_id TYPE INTEGER USING NULL'
    
    alter_table(:products) do
      add_foreign_key :user_id, :users, type: :integer, null: true, on_delete: :set_null
    end
    
    puts 'Reverted users.id and products.user_id to INTEGER'
  end
end
