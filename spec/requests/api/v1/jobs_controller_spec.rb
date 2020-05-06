require 'rails_helper'

class TestRoutine
  lev_routine use_jobba: true

  protected

  def exec
  end
end

RSpec.describe Api::V1::JobsController, type: :request, api: true, version: :v1 do
  include ActiveJob::TestHelper

  let(:user)  { FactoryBot.create(:user_profile) }
  let(:admin) { FactoryBot.create(:user_profile, :administrator) }

  let(:user_token)  { FactoryBot.create(:doorkeeper_access_token, resource_owner_id: user.id) }
  let(:admin_token) { FactoryBot.create(:doorkeeper_access_token, resource_owner_id: admin.id) }

  before(:all) { Jobba.all.to_a.each(&:delete!) }

  after(:all)  { Jobba.all.to_a.each(&:delete!) }

  context 'GET #index' do
    it 'is for admins only' do
      expect do
        api_get api_jobs_url, user_token
      end.to raise_error(SecurityTransgression)
    end

    it 'returns all the jobs that have been queued and worked' do
      job_id1 = TestRoutine.perform_later
      job_id2 = TestRoutine.perform_later

      job1 = Api::V1::JobRepresenter.new(Jobba.find(job_id1))
      job2 = Api::V1::JobRepresenter.new(Jobba.find(job_id2))

      api_get api_jobs_url, admin_token

      json_response = JSON.parse(response.body)
      expect(json_response).to contain_exactly(job1.as_json, job2.as_json)
    end
  end

  context 'GET #show' do
    let(:job_id) { TestRoutine.perform_later }

    it 'returns the status of queued jobs' do
      api_get api_job_url(job_id), user_token
      expect(response).to have_http_status :success
      expect(response.body_as_hash).to include({ status: 'queued' })
    end

    it 'returns 404 Not Found if the job does not exist' do
      api_get api_job_url(42), user_token
      expect(response).to have_http_status :not_found
      expect(response.body_as_hash).to(
        include(errors: [ { code: 'job_not_found', message: 'Job not found' } ], status: 404)
      )
    end

    context 'with inline jobs' do
      around(:all) { |all| perform_enqueued_jobs { all.run } }

      it 'returns the status of succeeded jobs' do
        api_get api_job_url(job_id), user_token

        expect(response).to have_http_status :success
        expect(response.body_as_hash).to include(status: 'succeeded')
      end

      it 'works end-2-end for ExportPerformanceReport' do
        user = FactoryBot.create(:user_profile)
        course = FactoryBot.create :course_profile_course
        user_token = FactoryBot.create :doorkeeper_access_token, resource_owner_id: user.id

        AddUserAsCourseTeacher[course: course, user: user]

        begin
          job_id = Tasks::ExportPerformanceReport.perform_later(
            course: course, role: Entity::Role.last
          )

          api_get api_job_url(job_id), user_token

          url = Tasks::Models::PerformanceReportExport.last.url

          expect(response.body_as_hash[:url]).to eq(url)
        ensure
          Tasks::Models::PerformanceReportExport.all.each do |performance_report_export|
            performance_report_export&.export&.file&.delete
          end
        end
      end
    end
  end
end
