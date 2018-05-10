require 'rails_helper'

class TestRoutine
  lev_routine use_jobba: true

  protected

  def exec
  end
end

RSpec.describe Api::V1::JobsController, type: :controller, api: true, version: :v1 do
  include ActiveJob::TestHelper

  let(:user) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:user, :administrator) }

  let(:user_token) { FactoryBot.create(:doorkeeper_access_token, resource_owner_id: user.id) }
  let(:admin_token) { FactoryBot.create(:doorkeeper_access_token, resource_owner_id: admin.id) }

  before(:all) { Jobba.all.to_a.each(&:delete!) }

  after(:all)  { Jobba.all.to_a.each(&:delete!) }

  context 'GET #index' do
    it 'is for admins only' do
      expect do
        api_get :index, user_token
      end.to raise_error(SecurityTransgression)
    end

    it 'returns all the jobs that have been queued and worked' do
      job_id1 = TestRoutine.perform_later
      job_id2 = TestRoutine.perform_later

      job1 = Api::V1::JobRepresenter.new(Jobba.find(job_id1))
      job2 = Api::V1::JobRepresenter.new(Jobba.find(job_id2))

      api_get :index, admin_token

      json_response = JSON.parse(response.body)
      expect(json_response).to contain_exactly(job1.as_json, job2.as_json)
    end
  end

  context 'GET #show' do
    let(:job_id) { TestRoutine.perform_later }

    it 'returns the status of queued jobs' do
      api_get :show, user_token, parameters: { id: job_id }
      expect(response).to have_http_status :success
      expect(response.body_as_hash).to include({ status: 'queued' })
    end

    it 'returns 404 Not Found if the job does not exist' do
      api_get :show, user_token, parameters: { id: 42 }
      expect(response).to have_http_status :not_found
      expect(response.body_as_hash).to include(errors: [{code: 'job_not_found',
                                                         message: 'Job not found'}], status: 404)
    end

    context 'with inline jobs' do
      before(:each) do
        ActiveJob::Base.queue_adapter = :inline
      end

      after(:each) do
        ActiveJob::Base.queue_adapter = :test
      end

      it 'returns the status of succeeded jobs' do
        api_get :show, user_token, parameters: { id: job_id }

        expect(response).to have_http_status :success
        expect(response.body_as_hash).to include({ status: 'succeeded' })
      end

      it 'works end-2-end for ExportPerformanceReport' do
        user = FactoryBot.create(:user)
        course = FactoryBot.create :course_profile_course
        user_token = FactoryBot.create :doorkeeper_access_token, resource_owner_id: user.id

        AddUserAsCourseTeacher[course: course, user: user]

        begin
          job_id = Tasks::ExportPerformanceReport.perform_later(course: course,
                                                                role: Entity::Role.last)

          api_get :show, user_token, parameters: { id: job_id }

          url = Tasks::Models::PerformanceReportExport.last.url

          expect(response.body_as_hash[:url]).to eq(url)
        ensure
          Tasks::Models::PerformanceReportExport.all.each do |performance_report_export|
            performance_report_export.try(:export).try(:file).try(:delete)
          end
        end
      end
    end
  end
end
