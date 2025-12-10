#!/bin/sh

set -e

bundle exec ruby -r sequel -r ./config/database -e "
  require 'sequel/extensions/migration'
  
  puts 'Checking migration status...'
  
  begin
    Sequel::Migrator.check_current(DB, './db/migrations')
    puts 'Database schema is up to date - no migrations needed'
  rescue Sequel::Migrator::NotCurrentError
    puts 'Pending migrations detected, applying them...'
    Sequel::Migrator.run(DB, './db/migrations')
    puts 'All migrations applied successfully'
  rescue => e
    puts \"ERROR: Migration failed - #{e.message}\"
    puts e.backtrace.first(5).join(\"\n\")
    exit 1
  end
  
  # Display current migration version
  current_version = DB[:schema_info].first
  if current_version
    puts \"Current schema version: #{current_version[:version]}\"
  end
"

if [ $? -ne 0 ]; then
  echo "ERROR: Migration process failed"
  exit 1
fi

exec "$@"
