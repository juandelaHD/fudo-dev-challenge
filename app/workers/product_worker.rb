# frozen_string_literal: true

require_relative '../../lib/job_queue'
require_relative '../services/product_service'

class ProductWorker
  class << self
    attr_reader :thread, :running

    def start
      return if @running

      @running = true
      @thread = Thread.new do
        puts "[ProductWorker] Worker started and listening for jobs..."
        
        loop do
          begin
            job = JobQueue.pop_job 
            
            next unless job

            process_job(job)
          rescue => e
            warn "[ProductWorker] Error in worker loop: #{e.message}"
            warn e.backtrace.first(ENV['ERROR_BACKTRACE_LINES'].to_i || 5).join("\n")
          end
        end
      end

      @thread.abort_on_exception = false
      puts "[ProductWorker] Worker thread initialized"
    end

    def stop
      @running = false
      @thread&.kill
      puts "[ProductWorker] Worker stopped"
    end

    def status
      {
        running: @running,
        thread_alive: @thread&.alive? || false,
        pending_jobs: JobQueue.pending_count
      }
    end

    private

    def process_job(job)
      job_id = job[:id]
      
      puts "[ProductWorker] Processing job #{job_id}..."
      
      JobQueue.update_job(job_id, {
        status: 'processing',
        started_at: Time.now
      })

      begin
        case job[:type]
        when 'create_product'
          process_create_product(job)
        else
          raise "Unknown job type: #{job[:type]}"
        end
      rescue => e
        handle_job_error(job_id, e)
      end
    end

    def process_create_product(job)
      job_id = job[:id]
      payload = job[:payload]

      sleep(ENV['SIMULATE_PROCESSING_DELAY'].to_i || 3)

      product = ProductService.create_product(
        name: payload[:name],
        description: payload[:description],
        user_id: payload[:user_id]
      )

      JobQueue.update_job(job_id, {
        status: 'completed',
        completed_at: Time.now,
        result: product
      })

      puts "[ProductWorker] Job #{job_id} completed successfully. Product ID: #{product[:id]}"
      
    rescue ProductService::DuplicateProductError => e
      JobQueue.update_job(job_id, {
        status: 'failed',
        completed_at: Time.now,
        error: {
          type: 'DuplicateProductError',
          message: e.message
        }
      })
      puts "[ProductWorker] Job #{job_id} failed: #{e.message}"
      
    rescue ProductService::ProductValidationError => e
      JobQueue.update_job(job_id, {
        status: 'failed',
        completed_at: Time.now,
        error: {
          type: 'ProductValidationError',
          message: e.message
        }
      })
      puts "[ProductWorker] Job #{job_id} failed: #{e.message}"
    end

    def handle_job_error(job_id, error)
      JobQueue.update_job(job_id, {
        status: 'failed',
        completed_at: Time.now,
        error: {
          type: error.class.name,
          message: error.message,
          backtrace: error.backtrace.first(5)
        }
      })
      
      warn "[ProductWorker] Job #{job_id} failed with error: #{error.message}"
      warn error.backtrace.first(5).join("\n")
    end
  end
end
