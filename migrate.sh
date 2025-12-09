#!/bin/bash

# Script for running database migrations inside the Docker container

set -e

echo "Running database migrations..."
docker-compose exec -T app bundle exec ruby -r sequel -r ./config/database -e "
  require 'sequel/extensions/migration'
  puts 'Checking migration status...'
  begin
    Sequel::Migrator.check_current(DB, '/app/db/migrations')
    puts 'Database is already up to date'
  rescue Sequel::Migrator::NotCurrentError
    puts 'Pending migrations found, running them...'
    Sequel::Migrator.run(DB, '/app/db/migrations')
    puts 'Migrations completed successfully'
  end
"