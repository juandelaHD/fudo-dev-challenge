# frozen_string_literal: true

require_relative '../models/product'
require_relative '../serializers/product_serializer'

class ProductService
  class ProductError < StandardError; end
  class ProductNotFoundError < ProductError; end
  class ProductValidationError < ProductError; end
  class DuplicateProductError < ProductError; end

  def self.list_products(page: Product::DEFAULT_PAGE, per_page: Product::DEFAULT_PER_PAGE)
    page = [page.to_i, Product::DEFAULT_PAGE].max
    per_page = [[per_page.to_i, Product::MAX_PER_PAGE].min, Product::MIN_PER_PAGE].max
    
    products = Product.paginated(page: page, per_page: per_page)
    total_count = Product.count
    total_pages = (total_count.to_f / per_page).ceil

    {
      products: ProductSerializer.serialize_collection(products),
      pagination: {
        page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: total_pages
      }
    }
  end

  def self.create_product(name:, description: nil, user_id:)
    product = Product.new(
      name: name.to_s.strip,
      description: description&.to_s&.strip,
      user_id: user_id
    )
    
    product.save
    
    ProductSerializer.serialize(product)
  rescue Sequel::UniqueConstraintViolation
    raise DuplicateProductError, 'A product with this name already exists'
  rescue Sequel::ValidationFailed => e
    raise ProductValidationError, e.message
  end
end
