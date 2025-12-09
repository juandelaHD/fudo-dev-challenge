require 'bcrypt'

class User < Sequel::Model
  plugin :validation_helpers
  plugin :json_serializer
  plugin :timestamps
  
  BCRYPT_COST_DEFAULT = 12

  one_to_many :products
  
  def to_hash(*_args)
    {
      id: id,
      email: email,
      created_at: created_at.iso8601
    }
  end
  
  def password=(new_password)
    cost = ENV.fetch('BCRYPT_COST', BCRYPT_COST_DEFAULT).to_i
    self.password_hash = BCrypt::Password.create(new_password, cost: cost)
  end
  
  def authenticate(password)
    BCrypt::Password.new(password_hash) == password
  rescue BCrypt::Errors::InvalidHash
    false
  end
  
  def validate
    super
    validates_presence [:email, :password_hash]
    validates_unique :email
    validates_format(/\A[^@\s]+@[^@\s]+\z/, :email, message: 'must be a valid email')
    validates_min_length 3, :password_hash
  end
end
