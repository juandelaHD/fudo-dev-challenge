# frozen_string_literal: true

require_relative 'base_controller'
require_relative '../services/product_service'
require_relative '../validators/product_validator'
require_relative '../../lib/job_queue'
require 'securerandom'

class ProductsController < BaseController
  
  def index
    page = params['page']&.to_i
    per_page = params['per_page']&.to_i || params['size']&.to_i
    
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
    
    async = params[:async] == true || params[:async] == 'true'
    
    if async
      existing_product = ProductService.check_duplicate(name: validation[:data][:name])
      if existing_product
        return conflict(
          'A product with this name already exists',
          path: request.path_info
        )
      end
      
      user_pending_jobs = JobQueue.pending_count_by_user(current_user_id)
      max_user_pending_jobs = (ENV['MAX_USER_PENDING_JOBS'] || 10).to_i
      
      if user_pending_jobs >= max_user_pending_jobs
        return too_many_requests(
          "You have too many pending jobs (#{user_pending_jobs}/#{max_user_pending_jobs}). Please wait for some to complete.",
          path: request.path_info,
          details: {
            pending_jobs: user_pending_jobs,
            max_allowed: max_user_pending_jobs,
            retry_after: '60s'
          }
        )
      end
      
      job_id = SecureRandom.uuid
      
      begin
        JobQueue.enqueue(
          job_id,
          'create_product',
          {
            name: validation[:data][:name],
            description: validation[:data][:description],
            user_id: current_user_id
          }
        )
        
        meta = {
          job_id: job_id,
          status: 'accepted',
          message: 'Product creation queued for processing',
          status_url: resource_location('jobs', job_id)
        }
        
        accepted({ job_id: job_id }, meta: meta)
      rescue JobQueue::QueueFullError => e
        service_unavailable(
          e.message,
          path: request.path_info,
          details: {
            queue_size: JobQueue.size,
            max_capacity: JobQueue.max_capacity,
            available_capacity: JobQueue.available_capacity,
            retry_after: '30s',
            suggestion: 'Please try again after 30 seconds.'
          }
        )
      end
    else
      product = ProductService.create_product(
        name: validation[:data][:name],
        description: validation[:data][:description],
        user_id: current_user_id
      )
      
      meta = {
        location: resource_location('products', product[:id])
      }
      
      created({ product: product }, meta: meta)
    end
  rescue ProductService::ProductValidationError => e
    bad_request(e.message, path: request.path_info)
  rescue ProductService::DuplicateProductError => e
    conflict(e.message, path: request.path_info)
  rescue ProductService::ProductError => e
    unprocessable_entity(e.message, path: request.path_info)
  end
end
