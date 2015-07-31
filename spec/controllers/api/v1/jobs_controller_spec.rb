require 'rails_helper'

RSpec.describe Api::V1::JobsController, type: :controller, api: true, version: :v1 do
  include ActiveJob::TestHelper

  let(:user) { FactoryGirl.create(:user_profile) }
  let(:admin) { FactoryGirl.create(:user_profile, :administrator) }

  let(:user_token) { FactoryGirl.create(:doorkeeper_access_token,
                                        resource_owner_id: user.id) }
  let(:admin_token) { FactoryGirl.create(:doorkeeper_access_token,
                                         resource_owner_id: admin.id) }

  before do
    stub_const 'TestRoutine', Class.new
    TestRoutine.class_eval {
      lev_routine
      protected
      def exec; end
    }
  end

  describe 'GET #index' do
    it 'is for admins only' do
      expect {
        api_get :index, user_token
      }.to raise_error(SecurityTransgression)
    end

    it 'returns all the jobs that have been queued and worked' do
      job_id1 = TestRoutine.perform_later
      job_id2 = TestRoutine.perform_later

      job1 = Lev::BackgroundJob.find(job_id1)
      job2 = Lev::BackgroundJob.find(job_id2)

      api_get :index, admin_token

      json_response = JSON.parse(response.body)
      expect(json_response).to eq([job1.as_json, job2.as_json])
    end
  end

  describe 'GET #show' do
    let(:job_id) { TestRoutine.perform_later }

    it 'returns the status of queued jobs' do
      api_get :show, user_token, parameters: { id: job_id }
      expect(response).to have_http_status(202)
      expect(response.body_as_hash).to include({ status: 'queued' })
    end

    it 'returns the status of completed jobs' do
      ActiveJob::Base.queue_adapter = :inline

      api_get :show, user_token, parameters: { id: job_id }

      expect(response).to have_http_status(200)
      expect(response.body_as_hash).to include({ status: 'completed' })

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

      url = Tasks::Models::PerformanceReportExport.last.url

      expect(response.body_as_hash[:url]).to eq(url)

      ActiveJob::Base.queue_adapter = :test
    end
  end
end
