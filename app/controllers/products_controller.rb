# frozen_string_literal: true

require_relative 'base_controller'
require_relative '../services/product_service'
require_relative '../validators/product_validator'

class ProductsController < BaseController
  
  def index
    page = params['page']&.to_i
    per_page = params['size']&.to_i || params['per_page']&.to_i
    
    result = ProductService.list_products(page: page, per_page: per_page)
    
    meta = build_pagination_meta(
      'products',
      result[:pagination][:page],
      result[:pagination][:per_page],
      result[:pagination][:total_pages],
      result[:pagination][:total_count]
    )
    
    links = build_pagination_links(
      'products',
      result[:pagination][:page],
      result[:pagination][:per_page],
      result[:pagination][:total_pages]
    )

    ok(result[:products], meta: meta, links: links)
  end
  
  def create
    params = parse_json_body
    
    validation = ProductValidator.validate_create(params)
    unless validation[:success]
      return bad_request('Validation failed', details: validation[:errors], path: request.path_info)
    end
    
    product = ProductService.create_product(
      name: validation[:data][:name],
      description: validation[:data][:description],
      user_id: current_user_id
    )
    
    meta = {
      location: resource_location('products', product[:id])
    }
    
    created({ product: product }, meta: meta)
  rescue ProductService::ProductValidationError => e
    bad_request(e.message, path: request.path_info)
  rescue ProductService::DuplicateProductError => e
    conflict(e.message, path: request.path_info)
  rescue ProductService::ProductError => e
    unprocessable_entity(e.message, path: request.path_info)
  end
end
