# frozen_string_literal: true

class ProductSerializer
  def self.serialize(product)
    {
      id: product.id,
      name: product.name,
      description: product.description,
      created_at: product.created_at.iso8601,
      updated_at: product.updated_at.iso8601
    }
  end

  def self.serialize_collection(products)
    products.map { |product| serialize(product) }
  end
end
