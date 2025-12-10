# frozen_string_literal: true

require_relative '../../lib/job_queue'
require_relative '../services/product_service'

class ProductWorker
  
  class ShutdownInterrupt < StandardError; end
  
  THREAD_TIMEOUT = 5
  
  class << self
    attr_reader :thread, :running

    def start
      return if @running

      @running = true
      @processing_job = nil
      @thread = Thread.new do
        puts "[ProductWorker] Worker started and listening for jobs..."
        
        while @running
          begin
            job = JobQueue.pop_job
            
            if job.nil?
              break
            end
            
            @processing_job = job
            process_job(job)
            @processing_job = nil
          rescue => e
            warn "[ProductWorker] Error in worker loop: #{e.message}"
            warn e.backtrace.first(ENV['ERROR_BACKTRACE_LINES'].to_i || 5).join("\n")
            @processing_job = nil
            break unless @running
          end
        end
        
        puts "[ProductWorker] Worker loop exited cleanly"
      end

      @thread.abort_on_exception = false
      puts "[ProductWorker] Worker thread initialized"
    end

    def stop
      return unless @running
      @running = false
      JobQueue.close
      
      if @processing_job
        job_id = @processing_job[:id]
        puts "[ProductWorker] Worker is processing job #{job_id}, interrupting..."
        $stdout.flush
        @thread&.raise(ShutdownInterrupt)
      end
      
      puts "[ProductWorker] Waiting for worker thread to finish (timeout: #{THREAD_TIMEOUT}s)..."
      $stdout.flush
      
      @thread&.join(THREAD_TIMEOUT)
      
      if @thread&.alive?
        warn "[ProductWorker] Thread did not stop gracefully after #{THREAD_TIMEOUT}s, forcing termination"
        @thread&.kill
      else
        puts "[ProductWorker] Worker thread stopped gracefully"
      end
      
      puts "[ProductWorker] Worker stopped successfully"
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
      rescue ShutdownInterrupt => e
        JobQueue.update_job(job_id, {
          status: 'cancelled',
          completed_at: Time.now,
          error: {
            type: 'ShutdownInterruption',
            message: 'Job processing was interrupted by worker shutdown'
          }
        })
        puts "[ProductWorker] Job #{job_id} cancelled due to shutdown (interrupted)"
      rescue => e
        handle_job_error(job_id, e)
      end
    end

    def process_create_product(job)
      job_id = job[:id]
      payload = job[:payload]

      delay = ENV['SIMULATE_PROCESSING_DELAY'].to_i
      delay = 3 if delay <= 0
      sleep(delay)
      
      unless @running
        JobQueue.update_job(job_id, {
          status: 'cancelled',
          completed_at: Time.now,
          error: {
            type: 'ShutdownInterruption',
            message: 'Job processing was interrupted by worker shutdown'
          }
        })
        puts "[ProductWorker] Job #{job_id} cancelled due to shutdown"
        return
      end

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
