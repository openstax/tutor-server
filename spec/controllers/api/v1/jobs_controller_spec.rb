require 'rails_helper'

RSpec.describe Api::V1::JobsController, type: :controller, api: true, version: :v1 do
  include ActiveJob::TestHelper

  let(:user) {
    profile = FactoryGirl.create(:user_profile)
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }
  let(:admin) {
    profile = FactoryGirl.create(:user_profile, :administrator)
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }

  let(:user_token) { FactoryGirl.create(:doorkeeper_access_token, resource_owner_id: user.id) }
  let(:admin_token) { FactoryGirl.create(:doorkeeper_access_token, resource_owner_id: admin.id) }

  before(:all) do
    @original_job_store = Lev.configuration.job_store
    Lev.configuration.job_store = ActiveSupport::Cache::MemoryStore.new
  end

  after(:all)  { Lev.configuration.job_store = @original_job_store }

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

    context 'with inline jobs' do
      before(:each) do
        ActiveJob::Base.queue_adapter = :inline
      end

      after(:each) do
        ActiveJob::Base.queue_adapter = :test
      end

      it 'returns the status of completed jobs' do
        api_get :show, user_token, parameters: { id: job_id }

        expect(response).to have_http_status(200)
        expect(response.body_as_hash).to include({ status: 'completed' })
      end

      it 'works end-2-end for ExportPerformanceReport' do
        profile = FactoryGirl.create(:user_profile)
        strategy = User::Strategies::Direct::User.new(profile)
        user = User::User.new(strategy: strategy)
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
