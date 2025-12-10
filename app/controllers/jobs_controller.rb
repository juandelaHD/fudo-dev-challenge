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
    
    if job.dig(:payload, :user_id) != current_user_id
      return not_found("Job not found", path: request.path_info)
    end
    
    job_response = JobSerializer.serialize(job)
    
    ok({ job: job_response })
  end
  
  def index
    per_page = params['per_page']&.to_i || 50
    per_page = [per_page, 100].min
    
    jobs = JobQueue.list_jobs_by_user(user_id: current_user_id, limit: per_page)
    jobs_response = JobSerializer.serialize_collection(jobs)
    
    meta = {
      count: jobs_response.size,
      total_pending: JobQueue.pending_count_by_user(current_user_id)
    }
    
    ok(jobs_response, meta: meta)
  end
  
  private
end
