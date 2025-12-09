class Product < Sequel::Model
  plugin :validation_helpers
  plugin :json_serializer
  plugin :timestamps
  
  DEFAULT_PAGE = 1
  DEFAULT_PER_PAGE = 20
  MIN_PER_PAGE = 1
  MAX_PER_PAGE = 100
  
  many_to_one :user
  one_to_many :product_sync_logs
  many_to_many :sync_logs, join_table: :product_sync_logs
  
  def self.paginated(page: DEFAULT_PAGE, per_page: DEFAULT_PER_PAGE)
    page = [page.to_i, DEFAULT_PAGE].max
    per_page = [[per_page.to_i, MAX_PER_PAGE].min, MIN_PER_PAGE].max
    
    offset = (page - 1) * per_page
    
    order(Sequel.desc(:created_at))
      .limit(per_page)
      .offset(offset)
      .all
  end
  
  def self.synced
    where(Sequel.~(external_id: nil))
  end
  
  def self.local
    where(external_id: nil)
  end
  
  def self.created_by_user
    where(Sequel.~(user_id: nil))
  end
  
  def synced?
    !external_id.nil?
  end
  
  def created_by_user?
    !user_id.nil?
  end
  
  def validate
    super
    validates_presence [:name]
    validates_unique :name
    validates_max_length 255, :name
    
    validates_unique :external_id if external_id
  end
end
