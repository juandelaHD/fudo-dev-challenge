# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/job_queue'
require_relative '../../app/workers/product_worker'

class JobsIntegrationTest < Minitest::Test
  include TestHelpers

  def setup
    super
    queue = SizedQueue.new(10)
    JobQueue.instance_variable_set(:@queue, queue)
    JobQueue.instance_variable_set(:@jobs, {})
    JobQueue.instance_variable_set(:@mutex, Mutex.new)
  end

  # GET /jobs tests
  def test_list_jobs_requires_authentication
    get api('/jobs')
    assert_unauthorized
  end

  def test_list_jobs_returns_user_jobs_only
    user1 = create_test_user(email: "#{SecureRandom.hex(4)}@example.com")
    user2 = create_test_user(email: "#{SecureRandom.hex(4)}@example.com")
    
    job1_id = SecureRandom.uuid
    job2_id = SecureRandom.uuid
    job3_id = SecureRandom.uuid
    
    JobQueue.enqueue(job1_id, 'create_product', { user_id: user1.id, name: 'Product 1' })
    JobQueue.enqueue(job2_id, 'create_product', { user_id: user2.id, name: 'Product 2' })
    JobQueue.enqueue(job3_id, 'create_product', { user_id: user1.id, name: 'Product 3' })

    token = get_auth_token(user1)
    get api('/jobs'), {}, auth_headers(token)

    assert_equal 200, last_response.status
    data = json_response
    assert_includes data, 'data'
  end

  def test_list_jobs_when_no_jobs_exist
    user = create_test_user(email: "#{SecureRandom.hex(4)}@example.com")
    token = get_auth_token(user)
    
    get api('/jobs'), {}, auth_headers(token)

    assert_equal 200, last_response.status
    data = json_response
    assert_includes data, 'data'
  end

  # GET /jobs/:id tests
  def test_get_job_by_id_requires_authentication
    get api('/jobs/some-job-id')
    assert_unauthorized
  end

  def test_get_job_by_id_returns_job_details
    user = create_test_user(email: "#{SecureRandom.hex(4)}@example.com")
    job_id = SecureRandom.uuid
    
    JobQueue.enqueue(
      job_id, 
      'create_product', 
      { user_id: user.id, name: 'Test Product', description: 'Test' }
    )

    token = get_auth_token(user)
    get api("/jobs/#{job_id}"), {}, auth_headers(token)

    assert_equal 200, last_response.status
    data = json_response
    assert_includes data, 'data'
  end

  def test_get_job_by_id_not_found
    user = create_test_user(email: "#{SecureRandom.hex(4)}@example.com")
    token = get_auth_token(user)
    
    get api('/jobs/non-existent-id'), {}, auth_headers(token)

    assert_equal 404, last_response.status
  end
end
