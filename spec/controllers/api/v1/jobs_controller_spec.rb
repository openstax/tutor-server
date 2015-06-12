require 'mock_redis'
require 'rails_helper'

RSpec.describe Api::V1::JobsController, type: :controller, api: true, version: :v1 do
  include ActiveJob::TestHelper

  let(:user) { Entity::User.create! }
  let(:user_token) { FactoryGirl.create(:doorkeeper_access_token,
                                        resource_owner_id: user.id) }
  before do
    stub_const 'TestRoutine', Class.new
    TestRoutine.class_eval {
      lev_routine

      protected
      def exec
        outputs[:job_data] = { filename: 'something' }
      end
    }
  end

  describe 'GET #show' do
    let(:job_id) { TestRoutine.perform_later }

    it 'returns the status of queued jobs' do
      api_get :show, user_token, parameters: { id: job_id }
      expect(response.body_as_hash[:status]).to match(
        hash_including(status: 'queued')
      )
    end

    it 'returns the status of working jobs' do
      allow(Resque::Plugins::Status::Hash).to receive(:get)
        .with(job_id).and_return(Hashie::Mash.new(status: 'working'))

      api_get :show, user_token, parameters: { id: job_id }

      expect(response.body_as_hash[:status]).to match(
        hash_including(status: 'working')
      )
    end

    it 'returns the status of completed jobs' do
      Resque.inline = true

      api_get :show, user_token, parameters: { id: job_id }

      expect(response.body_as_hash[:status]).to match(
        hash_including(status: 'completed', filename: 'something')
      )
    end
  end
end
