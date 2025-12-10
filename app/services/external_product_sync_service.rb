# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'openssl'
require 'set'
require_relative 'base_sync_service'
require_relative '../models/product'
require_relative '../models/product_sync_log'

# Service for synchronizing products from external Fudo API.
# Runs once on first application startup.
class ExternalProductSyncService < BaseSyncService
  EXTERNAL_API_URL = ENV['EXTERNAL_PRODUCTS_URL']&.strip
  REQUEST_TIMEOUT = 10
  MAX_RETRIES = 3

  class << self
    private

    # Required: Returns the sync type for this service
    def sync_type
      SyncLog::SYNC_TYPE_EXTERNAL
    end

    # Required: Fetches items from external source
    def fetch_items
      fetch_external_products
    end

    # Required: Imports items into the database
    def import_items(items, sync_log)
      import_products(items, sync_log)
    end

    # Hook: Determines if sync should run
    def should_sync?
      if EXTERNAL_API_URL.nil? || EXTERNAL_API_URL.empty?
        log_error "EXTERNAL_PRODUCTS_URL not set; skipping sync"
        return false
      end
      true
    end

    # Hook: Validates configuration before sync
    def validate_configuration!
      return if EXTERNAL_API_URL

      raise SyncError, "EXTERNAL_PRODUCTS_URL must be configured"
    end

    # Fetches products from external Fudo API with retry logic
    def fetch_external_products
      begin
        uri = URI.parse(EXTERNAL_API_URL)
      rescue URI::InvalidURIError => e
        raise APIError, "Invalid EXTERNAL_PRODUCTS_URL: #{e.message}"
      end

      retries = 0
      begin
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.open_timeout = REQUEST_TIMEOUT
        http.read_timeout = REQUEST_TIMEOUT
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER if http.use_ssl?

        request = Net::HTTP::Post.new(uri.request_uri)
        request['Content-Type'] = 'application/json'
        request['Accept'] = 'application/json'

        log_info "Fetching products from #{uri}..."
        response = http.request(request)

        unless response.is_a?(Net::HTTPSuccess)
          raise APIError, "API returned #{response.code}: #{response.message}"
        end

        data = JSON.parse(response.body)
        products = data['data']

        unless products.is_a?(Array)
          raise APIError, "Invalid response format: expected 'data' to be an array"
        end

        log_info "Received #{products.size} products from external API"
        products
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        retries += 1
        if retries <= MAX_RETRIES
          log_error "Timeout (attempt #{retries}/#{MAX_RETRIES}), retrying..."
          sleep(2**retries)
          retry
        end
        raise NetworkError, "Request timed out after #{MAX_RETRIES} retries: #{e.message}"
      rescue SocketError, Errno::ECONNREFUSED => e
        raise NetworkError, "Network error: #{e.message}"
      rescue JSON::ParserError => e
        raise APIError, "Invalid JSON response: #{e.message}"
      end
    end

    def import_products(products_data, sync_log)
      synced_count = 0
      skipped_count = 0

      existing_records = Product.select(:external_id, :name).all
      existing_external_ids = existing_records.map { |r| r[:external_id].to_s }.to_set
      existing_names = existing_records.map { |r| r[:name].to_s.downcase.strip }.to_set

      products_data.each do |product_data|
        external_id = product_data['id'].to_s
        name = product_data['name']&.strip

        next unless valid_product_data?(external_id, name)

        if existing_external_ids.include?(external_id) || existing_names.include?(name.to_s.downcase)
          skipped_count += 1
          next
        end

        begin
          DB.transaction do
            product = Product.create(
              name: name,
              description: nil,
              external_id: external_id,
              user_id: nil
            )
            ProductSyncLog.link(product, sync_log)
          end

          existing_external_ids.add(external_id)
          existing_names.add(name.to_s.downcase)

          synced_count += 1
        rescue Sequel::UniqueConstraintViolation
          skipped_count += 1
          log_error "Skipping duplicate due to DB constraint: #{name} (external_id: #{external_id})"
        rescue StandardError => e
          log_error "Failed to import product #{name}: #{e.message}"
        end
      end

      log_info "Import complete: #{synced_count} imported, #{skipped_count} skipped"
      synced_count
    end

    def valid_product_data?(external_id, name)
      if external_id.nil? || external_id.empty?
        log_error "Skipping product with missing external_id"
        return false
      end

      if name.nil? || name.empty?
        log_error "Skipping product with missing name (external_id: #{external_id})"
        return false
      end

      true
    end
  end
end
