# frozen_string_literal: true

require_relative '../models/sync_log'

class BaseSyncService
  class SyncError < StandardError; end
  class APIError < SyncError; end
  class NetworkError < SyncError; end

  class << self
    def sync_on_startup
      return unless should_sync?
      return if already_synced?

      log_info "No previous successful sync found, initiating first-time sync..."
      perform_sync
    rescue StandardError => e
      log_error "Failed to sync on startup: #{e.message}"
      log_error "Application will continue without synced data"
    end

    def perform_sync
      validate_configuration!
      
      sync_log = create_sync_log
      
      begin
        items = fetch_items
        synced_count = import_items(items, sync_log)
        
        complete_sync_log(sync_log, synced_count)
        
        log_info "Successfully synced #{synced_count} items"
        { success: true, synced_count: synced_count }
      rescue StandardError => e
        fail_sync_log(sync_log, e)
        raise
      end
    end

    private

    def sync_type
      raise NotImplementedError, "#{self.name} must implement #sync_type"
    end

    def fetch_items
      raise NotImplementedError, "#{self.name} must implement #fetch_items"
    end

    def import_items(items, sync_log)
      raise NotImplementedError, "#{self.name} must implement #import_items(items, sync_log)"
    end

    def should_sync?
      true
    end

    def validate_configuration!
    end

    def log_prefix
      "[#{self.name.gsub('Service', '')}]"
    end

    def already_synced?
      SyncLog.where(
        sync_type: sync_type,
        status: SyncLog::STATUS_COMPLETED
      ).count > 0
    end

    def create_sync_log
      SyncLog.create(
        sync_type: sync_type,
        status: SyncLog::STATUS_RUNNING,
        started_at: Time.now
      )
    end

    def complete_sync_log(sync_log, synced_count)
      sync_log.mark_completed!
    end

    def fail_sync_log(sync_log, error)
      sync_log.mark_failed!(error)
      log_error "Sync failed: #{error.message}"
    end

    def log_info(message)
      puts "#{log_prefix} #{message}"
    end

    def log_error(message)
      warn "#{log_prefix} #{message}"
    end
  end
end
