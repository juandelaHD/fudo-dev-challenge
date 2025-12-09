# frozen_string_literal: true

require 'thread'

class JobQueue
  class QueueFullError < StandardError; end

  MAX_CAPACITY = (ENV['JOB_QUEUE_MAX_CAPACITY'] || 10).to_i

  class << self
    def initialize_queue
      @queue = SizedQueue.new(MAX_CAPACITY) 
      @jobs = {}
      @mutex = Mutex.new
      @max_capacity = MAX_CAPACITY
    end

    def enqueue(job_id, job_type, payload)
      job_data = {
        id: job_id,
        type: job_type,
        payload: payload,
        status: 'pending',
        enqueued_at: Time.now,
        started_at: nil,
        completed_at: nil,
        result: nil,
        error: nil
      }
      
      begin
        @queue.push(job_data, true)
        
        @mutex.synchronize do
          @jobs[job_id] = job_data
        end
        
        puts "[JobQueue] Enqueued job #{job_id} (type: #{job_type}) - Queue size: #{@queue.size}/#{@max_capacity}"
        job_data
      rescue ThreadError
        warn "[JobQueue] Queue is FULL (#{@queue.size}/#{@max_capacity}). Rejecting job #{job_id}"
        raise QueueFullError, "Job queue is at capacity (#{@max_capacity}). Please try again later."
      end
    end

    def full?
      @queue.size >= @max_capacity
    end

    def empty?
      @queue.empty?
    end

    def available_capacity
      [@max_capacity - @queue.size, 0].max
    end

    def get_job(job_id)
      @mutex.synchronize do
        @jobs[job_id]
      end
    end

    def update_job(job_id, updates)
      @mutex.synchronize do
        if @jobs[job_id]
          @jobs[job_id].merge!(updates)
        end
      end
    end

    def list_jobs(limit: 50)
      @mutex.synchronize do
        @jobs.values.sort_by { |j| j[:enqueued_at] }.reverse.take(limit)
      end
    end

    def pending_count
      @mutex.synchronize do
        @jobs.values.count { |j| j[:status] == 'pending' }
      end
    end

    def size
      @queue.size
    end

    def max_capacity
      @max_capacity
    end
    
    def pop_job
      @queue.pop
    end
  end

  initialize_queue
end
