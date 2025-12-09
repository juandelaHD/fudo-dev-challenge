# frozen_string_literal: true

class JobSerializer
  def self.serialize(job)
    {
      id: job[:id],
      type: job[:type],
      status: job[:status],
      result: job[:result],
      error: job[:error],
      enqueued_at: job[:enqueued_at]&.iso8601,
      started_at: job[:started_at]&.iso8601,
      completed_at: job[:completed_at]&.iso8601
    }
  end

  def self.serialize_collection(jobs)
    jobs.map { |job| serialize(job) }
  end
end
