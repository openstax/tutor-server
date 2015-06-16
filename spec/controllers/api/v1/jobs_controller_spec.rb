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
        status.save(filename: 'something')
      end
    }
  end

  describe 'GET #show' do
    let(:job_id) { TestRoutine.perform_later }

    it 'returns the status of queued jobs' do
      api_get :show, user_token, parameters: { id: job_id }
      expect(response.body_as_hash).to eq({ state: 'queued' })
    end

    it 'returns the status of completed jobs' do
      ActiveJob::Base.queue_adapter = :inline

      api_get :show, user_token, parameters: { id: job_id }

      expect(response.body_as_hash).to eq({ state: 'completed',
                                            filename: 'something' })

      ActiveJob::Base.queue_adapter = :test
    end

    it 'works end-2-end for ExportPerformanceReport' do
      ActiveJob::Base.queue_adapter = :inline

      user = Entity::User.create!
      course = CreateCourse[name: 'Physics']
      user_token = FactoryGirl.create :doorkeeper_access_token,
                                      resource_owner_id: user.id

      AddUserAsCourseTeacher[course: course, user: user]
      job_id = Tasks::ExportPerformanceReport.perform_later(course: course,
                                                            role: Entity::Role.last)

      api_get :show, user_token, parameters: { id: job_id }
      expect(response.body_as_hash[:url]).to eq(Tasks::Models::PerformanceReportExport.last.url)

      ActiveJob::Base.queue_adapter = :test
    end
  end
end
