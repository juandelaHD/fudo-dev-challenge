# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'openssl'
require_relative '../models/product'
require_relative '../models/sync_log'
require_relative '../models/product_sync_log'

# Service for synchronizing products from external Fudo API.
# Runs once on first application startup.
class ExternalProductSyncService
  class SyncError < StandardError; end
  class APIError < SyncError; end
  class NetworkError < SyncError; end

  EXTERNAL_API_URL = ENV['EXTERNAL_PRODUCTS_URL']&.strip
  REQUEST_TIMEOUT = 10
  MAX_RETRIES = 3

  class << self
    def sync_on_startup
      if EXTERNAL_API_URL.nil? || EXTERNAL_API_URL.empty?
        warn "[ExternalSync] EXTERNAL_PRODUCTS_URL not set; skipping initial external sync"
        return
      end

      return if already_synced?

      puts "[ExternalSync] No previous successful sync found, initiating first-time sync..."
      perform_sync
    rescue StandardError => e
      warn "[ExternalSync] Failed to sync on startup: #{e.message}"
      warn "[ExternalSync] Application will continue without external products"
    end

    def perform_sync
      sync_log = create_sync_log
      
      begin
        products_data = fetch_external_products
        synced_count = import_products(products_data, sync_log)
        
        complete_sync_log(sync_log, synced_count)
        
        puts "[ExternalSync] Successfully synced #{synced_count} products"
        { success: true, synced_count: synced_count }
      rescue StandardError => e
        fail_sync_log(sync_log, e)
        raise
      end
    end

    private

    def already_synced?
      SyncLog.where(
        sync_type: SyncLog::SYNC_TYPE_EXTERNAL,
        status: SyncLog::STATUS_COMPLETED
      ).first != nil
    end

    def create_sync_log
      SyncLog.create(
        sync_type: SyncLog::SYNC_TYPE_EXTERNAL,
        status: SyncLog::STATUS_RUNNING,
        started_at: Time.now
      )
    end

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
        if http.use_ssl?
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        end

        request = Net::HTTP::Post.new(uri.request_uri)
        request['Content-Type'] = 'application/json'
        request['Accept'] = 'application/json'

        puts "[ExternalSync] Fetching products from #{uri}..."
        response = http.request(request)

        unless response.is_a?(Net::HTTPSuccess)
          raise APIError, "API returned #{response.code}: #{response.message}"
        end

        data = JSON.parse(response.body)
        products = data['data']

        unless products.is_a?(Array)
          raise APIError, "Invalid response format: expected 'data' to be an array"
        end

        puts "[ExternalSync] Received #{products.size} products from external API"
        products
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        retries += 1
        if retries <= MAX_RETRIES
          puts "[ExternalSync] Timeout (attempt #{retries}/#{MAX_RETRIES}), retrying..."
          sleep(2 ** retries)
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
          product = nil
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
          puts "[ExternalSync] Skipping duplicate due to DB constraint: #{name} (external_id: #{external_id})"
          next
        rescue StandardError => e
          warn "[ExternalSync] Failed to import product #{name}: #{e.message}"
          next
        end
      end

      puts "[ExternalSync] Import complete: #{synced_count} imported, #{skipped_count} skipped"
      synced_count
    end

    def valid_product_data?(external_id, name)
      if external_id.nil? || external_id.empty?
        warn "[ExternalSync] Skipping product with missing external_id"
        return false
      end

      if name.nil? || name.empty?
        warn "[ExternalSync] Skipping product with missing name (external_id: #{external_id})"
        return false
      end

      true
    end

    def complete_sync_log(sync_log, synced_count)
      sync_log.mark_completed!
    end

    def fail_sync_log(sync_log, error)
      sync_log.mark_failed!(error)
      warn "[ExternalSync] Sync failed: #{error.message}"
    end
  end
end
