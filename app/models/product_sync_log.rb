class ProductSyncLog < Sequel::Model
  plugin :validation_helpers
  plugin :timestamps, update_on_create: true
  
  many_to_one :product
  many_to_one :sync_log
  
  def validate
    super
    validates_presence [:product_id, :sync_log_id]
  end
  
  def self.link(product, sync_log)
    create(
      product_id: product.id,
      sync_log_id: sync_log.id
    )
  rescue Sequel::UniqueConstraintViolation
    nil
  end
end
