# frozen_string_literal: true

require_relative 'base_controller'
require_relative '../../lib/job_queue'
require_relative '../serializers/job_serializer'

class JobsController < BaseController
  
  def show
    job_id = params['id']
    
    job = JobQueue.get_job(job_id)
    
    unless job
      return not_found("Job not found", path: request.path_info)
    end
    
    job_response = JobSerializer.serialize(job)
    
    ok({ job: job_response })
  end
  
  def index
    limit = params['limit']&.to_i || 50
    limit = [limit, 100].min
    
    jobs = JobQueue.list_jobs(limit: limit)
    jobs_response = JobSerializer.serialize_collection(jobs)
    
    meta = {
      count: jobs_response.size,
      total_pending: JobQueue.pending_count
    }
    
    ok(jobs_response, meta: meta)
  end
  
  private
end
