require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Api::V1::PerformanceReportsController, type: :controller, api: true,
                                                      version: :v1, speed: :slow, vcr: VCR_OPTS do

  before(:all) do
    @course = FactoryBot.create :course_profile_course, :with_assistants
    @period = FactoryBot.create :course_membership_period, course: @course

    @teacher = FactoryBot.create(:user)
    @teacher_token = FactoryBot.create :doorkeeper_access_token, resource_owner_id: @teacher.id

    @role = AddUserAsCourseTeacher[course: @course, user: @teacher]
  end

  context 'with book' do
    before(:all) do
      DatabaseCleaner.start

      VCR.use_cassette("Api_V1_PerformanceReportsController/with_book", VCR_OPTS) do
        @ecosystem = FetchAndImportBookAndCreateEcosystem[
          book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b'
        ]
      end

      CourseContent::AddEcosystemToCourse.call(course: @course, ecosystem: @ecosystem)
    end

    after(:all)  { DatabaseCleaner.clean }

    context 'GET #index' do
      before(:all) do
        DatabaseCleaner.start

        student_1 = FactoryBot.create(:user, first_name: 'Student',
                                              last_name: 'One',
                                              full_name: 'Student One')
        @student_1_token = FactoryBot.create :doorkeeper_access_token,
                                              resource_owner_id: student_1.id

        student_2 = FactoryBot.create(:user, first_name: 'Student',
                                              last_name: 'Two',
                                              full_name: 'Student Two')

        student_3 = FactoryBot.create(:user, first_name: 'Student',
                                              last_name: 'Three',
                                              full_name: 'Student Three')

        student_4 = FactoryBot.create(:user, first_name: 'Student',
                                              last_name: 'Four',
                                              full_name: 'Student Four')

        SetupPerformanceReportData[course: @course,
                                   teacher: @teacher,
                                   students: [student_1, student_2, student_3, student_4],
                                   ecosystem: @ecosystem]
      end

      after(:all)  { DatabaseCleaner.clean }

      it 'calls GetPerformanceReport and PerformanceReportRepresenter with the proper arguments' do
        expect(GetPerformanceReport).to receive(:[])
          .with(course: @course, role: @role)
          .and_wrap_original { |method, *args| @result = method.call(*args) }
        expect(Api::V1::PerformanceReportRepresenter).to(
          receive(:new).and_wrap_original do |method, hash|
            expect(hash).to eq @result

            method.call(hash).tap do |representer|
              expect(representer).to receive(:to_json).and_call_original
            end
          end
        )

        api_get :index, @teacher_token, parameters: { id: @course.id }

        expect(response).to have_http_status :success
      end

      it 'returns 403 for users not in the course' do
        unknown = FactoryBot.create(:user)
        unknown_token = FactoryBot.create :doorkeeper_access_token, resource_owner_id: unknown.id

        expect do
          api_get :index, unknown_token, parameters: { id: @course.id }
        end.to raise_error(SecurityTransgression)
      end

      it 'returns 403 for students' do
        expect do
          api_get :index, @student_1_token, parameters: { id: @course.id }
        end.to raise_error SecurityTransgression
      end
    end
  end

  context 'POST #export' do
    context 'success' do
      after(:each) do
        Tasks::Models::PerformanceReportExport.all.each do |performance_report_export|
          performance_report_export.try!(:export).try!(:file).try!(:delete)
        end
      end

      it 'returns 202 for authorized teachers' do
        api_post :export, @teacher_token, parameters: { id: @course.id }
        expect(response.status).to eq(202)
        expect(response.body_as_hash[:job]).to match(%r{/api/jobs/[a-z0-9-]+})
      end

      it 'returns the job path for the performance book export for authorized teachers' do
        api_post :export, @teacher_token, parameters: { id: @course.id }
        expect(response.body_as_hash[:job]).to match(%r{/jobs/[a-f0-9-]+})
      end

      it 'does not blow up when the period name is more than 31 characters' do
        @period.update_attributes(name: 'a' * 50)
        api_post :export, @teacher_token, parameters: { id: @course.id }
        expect(response.status).to eq(202)
      end

      it 'does not blow up when the period name has invalid worksheet characters' do
        @period.update_attributes(name: '[p: 1 \/ 2? *]')
        api_post :export, @teacher_token, parameters: { id: @course.id }
        expect(response.status).to eq(202)
      end

      it 'does not blow up when period names collide for the first 31 characters' do
        @period.update_attributes(name: 'Super duper long period name number 1')
        FactoryBot.create :course_membership_period, course: @course,
                                                      name: 'Super duper long period name number 2'
        api_post :export, @teacher_token, parameters: { id: @course.id }
        expect(response.status).to eq(202)
      end
    end

    context 'failure' do
      it 'returns 403 for students' do
        student = FactoryBot.create(:user)
        student_token = FactoryBot.create(:doorkeeper_access_token,
                                           resource_owner_id: student.id)
        AddUserAsPeriodStudent[period: @period, user: student]

        expect do
          api_post :export, student_token, parameters: { id: @course.id }
        end.to raise_error(SecurityTransgression)
      end

      it 'returns 403 unauthorized users' do
        unknown = FactoryBot.create(:user)
        unknown_token = FactoryBot.create :doorkeeper_access_token,
                                           resource_owner_id: unknown.id

        expect do
          api_post :export, unknown_token, parameters: { id: @course.id }
        end.to raise_error(SecurityTransgression)
      end

      it 'returns 404 for non-existent courses' do
        expect do
          api_post :export, @teacher_token, parameters: { id: 'nope' }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'GET #exports' do
    context 'success' do
      before(:each) do
        @export = Tempfile.open(['test_export', '.xls']) do |file|
          FactoryBot.create(:tasks_performance_report_export,
                             export: file, course: @course, role: @role)
        end
      end

      after(:each) do
        Tasks::Models::PerformanceReportExport.all.each do |performance_report_export|
          performance_report_export.try!(:export).try!(:file).try!(:delete)
        end
      end

      it 'returns the filename, url, timestamp of all exports for the course' do
        api_get :exports, @teacher_token, parameters: { id: @course.id }

        expect(response.status).to eq(200)
        expect(response.body_as_hash.last[:filename]).not_to include('test_export')
        expect(response.body_as_hash.last[:filename]).to include('.xls')
        expect(response.body_as_hash.last[:url]).to eq(@export.url)
        expect(response.body_as_hash.last[:created_at]).not_to be_nil
      end
    end

    context 'failure' do
      it 'returns 403 for students' do
        student = FactoryBot.create(:user)
        student_token = FactoryBot.create(:doorkeeper_access_token, resource_owner_id: student.id)
        AddUserAsPeriodStudent[period: @period, user: student]

        expect do
          api_get :export, student_token, parameters: { id: @course.id }
        end.to raise_error(SecurityTransgression)
      end

      it 'returns 403 for users who are not teachers of the course' do
        unknown = FactoryBot.create(:user)
        unknown_token = FactoryBot.create :doorkeeper_access_token,
                                           resource_owner_id: unknown.id

        expect do
          api_get :exports, unknown_token, parameters: { id: @course.id }
        end.to raise_error(SecurityTransgression)
      end

      it 'returns 404 for non-existent courses' do
        expect do
          api_get :exports, @teacher_token, parameters: { id: 'nope' }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
