# frozen_string_literal: true

class UserSerializer
  def self.serialize(user)
    {
      id: user.id,
      email: user.email,
      created_at: user.created_at.iso8601,
      updated_at: user.updated_at.iso8601
    }
  end
end
