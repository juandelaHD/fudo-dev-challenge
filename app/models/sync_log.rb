class SyncLog < Sequel::Model
  plugin :validation_helpers
  plugin :json_serializer
  plugin :timestamps, update_on_create: false
  
  one_to_many :product_sync_logs
  many_to_many :products, join_table: :product_sync_logs
  
  STATUS_RUNNING = 'running'
  STATUS_COMPLETED = 'completed'
  STATUS_FAILED = 'failed'
  STATUSES = [STATUS_RUNNING, STATUS_COMPLETED, STATUS_FAILED].freeze
  
  SYNC_TYPE_EXTERNAL = 'external_products'
  SYNC_TYPE_MANUAL = 'manual_sync'
  SYNC_TYPES = [SYNC_TYPE_EXTERNAL, SYNC_TYPE_MANUAL].freeze
  
  def validate
    super
    validates_presence [:sync_type, :status]
    validates_includes STATUSES, :status
    validates_includes SYNC_TYPES, :sync_type
  end
  
  def running?
    status == STATUS_RUNNING
  end
  
  def completed?
    status == STATUS_COMPLETED
  end
  
  def failed?
    status == STATUS_FAILED
  end
  
  def mark_completed!
    update(
      status: STATUS_COMPLETED,
      completed_at: Time.now
    )
  end
  
  def mark_failed!(error)
    update(
      status: STATUS_FAILED,
      error_message: error.message,
      completed_at: Time.now
    )
  end
  
  def self.last_successful
    where(status: STATUS_COMPLETED)
      .order(Sequel.desc(:completed_at))
      .first
  end
  
  def duration
    return nil unless completed_at
    completed_at - started_at
  end
  
  def products_count
    product_sync_logs.count
  end
end
