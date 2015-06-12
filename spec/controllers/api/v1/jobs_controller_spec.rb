require 'rails_helper'

class TestJob < TrackableJob
  def perform
  end
end

RSpec.describe Api::V1::JobsController, type: :controller, api: true, version: :v1 do
  include ActiveJob::TestHelper

  let(:user) { Entity::User.create! }
  let(:user_token) { FactoryGirl.create(:doorkeeper_access_token,
                                        resource_owner_id: user.id) }

  describe 'GET #show' do
    let(:job) { TestJob.perform_later }

    it 'returns the status of queued jobs' do
      api_get :show, user_token, parameters: { id: job.job_id }
      expect(response.body_as_hash[:status]).to eq('queued')
    end

    it 'returns the status of working jobs' do
      allow(ActiveJobStatus::JobStatus).to receive(:get_status)
                                           .with(job_id: job.job_id) { 'working' }

      api_get :show, user_token, parameters: { id: job.job_id }

      expect(response.body_as_hash[:status]).to eq('working')
    end

    it 'returns the status of completed jobs' do
      job = nil

      perform_enqueued_jobs do
        job = TestJob.perform_later
      end

      api_get :show, user_token, parameters: { id: job.job_id }

      expect(response.body_as_hash[:status]).to eq('completed')
    end
  end
end
