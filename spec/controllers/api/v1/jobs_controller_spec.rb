require 'rails_helper'

RSpec.describe Api::V1::JobsController, type: :controller, api: true, version: :v1 do
  include ActiveJob::TestHelper

  let(:user) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:user, :administrator) }

  let(:user_token) { FactoryGirl.create(:doorkeeper_access_token, resource_owner_id: user.id) }
  let(:admin_token) { FactoryGirl.create(:doorkeeper_access_token, resource_owner_id: admin.id) }

  before(:all) do
    Jobba.all.to_a.each { |status| status.delete! }
  end

  after(:all) do
    Jobba.all.to_a.each { |status| status.delete! }
  end

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

      status1 = Jobba.find(job_id1)
      status2 = Jobba.find(job_id2)

      api_get :index, admin_token

      json_response = JSON.parse(response.body)
      expect(json_response).to eq([status1.as_json, status2.as_json])
    end
  end

  describe 'GET #show' do
    let(:job_id) { TestRoutine.perform_later }

    it 'returns the status of queued jobs' do
      api_get :show, user_token, parameters: { id: job_id }
      expect(response).to have_http_status :success
      expect(response.body_as_hash).to include({ status: 'queued' })
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
        user = FactoryGirl.create(:user)
        course = CreateCourse[name: 'Physics']
        user_token = FactoryGirl.create :doorkeeper_access_token, resource_owner_id: user.id

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
