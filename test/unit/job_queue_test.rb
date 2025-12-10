# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/job_queue'

class JobQueueTest < Minitest::Test
  def setup
    queue = SizedQueue.new(10)
    JobQueue.instance_variable_set(:@queue, queue)
    JobQueue.instance_variable_set(:@jobs, {})
    JobQueue.instance_variable_set(:@mutex, Mutex.new)
  end

  def test_enqueue_adds_job
    job_id = SecureRandom.uuid
    job_data = JobQueue.enqueue(job_id, 'test_job', { key: 'value' })
    
    assert_equal job_id, job_data[:id]
    assert_equal 'test_job', job_data[:type]
    assert_equal 'pending', job_data[:status]
  end

  def test_get_job_returns_job_data
    job_id = SecureRandom.uuid
    JobQueue.enqueue(job_id, 'test_job', { key: 'value' })
    
    job = JobQueue.get_job(job_id)
    assert_equal job_id, job[:id]
  end

  def test_list_jobs_by_user_filters_correctly
    user1_id = SecureRandom.uuid
    user2_id = SecureRandom.uuid
    
    job1_id = SecureRandom.uuid
    job2_id = SecureRandom.uuid
    job3_id = SecureRandom.uuid
    
    JobQueue.enqueue(job1_id, 'job1', { user_id: user1_id })
    JobQueue.enqueue(job2_id, 'job2', { user_id: user2_id })
    JobQueue.enqueue(job3_id, 'job3', { user_id: user1_id })
    
    user1_jobs = JobQueue.list_jobs_by_user(user_id: user1_id)
    
    assert_equal 2, user1_jobs.length
    job_ids = user1_jobs.map { |j| j[:id] }
    assert_includes job_ids, job1_id
    assert_includes job_ids, job3_id
    refute_includes job_ids, job2_id
  end

  def test_pending_count_by_user
    user_id = SecureRandom.uuid
    
    3.times do |i|
      JobQueue.enqueue(SecureRandom.uuid, "job#{i}", { user_id: user_id })
    end
    
    count = JobQueue.pending_count_by_user(user_id)
    assert_equal 3, count
  end

  def test_size_returns_queue_size
    JobQueue.enqueue(SecureRandom.uuid, 'job1', {})
    JobQueue.enqueue(SecureRandom.uuid, 'job2', {})
    
    assert_equal 2, JobQueue.size
  end
end
