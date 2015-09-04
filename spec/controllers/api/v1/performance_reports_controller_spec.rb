require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Api::V1::PerformanceReportsController, type: :controller, api: true,
                                                      version: :v1, speed: :slow, vcr: VCR_OPTS do

  let!(:course) { CreateCourse[name: 'Physics 101'] }
  let!(:period) { CreatePeriod[course: course] }

  context 'with book' do
    before(:all) do
      DatabaseCleaner.start

      VCR.use_cassette("Api_V1_PerformanceReportsController/with_book", VCR_OPTS) do
        @ecosystem = FetchAndImportBookAndCreateEcosystem[
          id: '93e2b09d-261c-4007-a987-0b3062fe154b'
        ]
      end
    end

    before(:each) do
      CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: @ecosystem)
    end

    after(:all) do
      DatabaseCleaner.clean
    end

    describe '#index' do
      let(:teacher) { FactoryGirl.create :user_profile }
      let(:teacher_token) { FactoryGirl.create :doorkeeper_access_token,
                              resource_owner_id: teacher.id }
      let(:student_1) { FactoryGirl.create :user_profile,
                                           first_name: 'Student',
                                           last_name: 'One',
                                           full_name: 'Student One' }
      let(:student_1_token) { FactoryGirl.create :doorkeeper_access_token,
                                resource_owner_id: student_1.id }
      let(:student_2) { FactoryGirl.create :user_profile,
                                           first_name: 'Student',
                                           last_name: 'Two',
                                           full_name: 'Student Two' }

      let(:student_2) { FactoryGirl.create :user_profile,
                                           first_name: 'Student',
                                           last_name: 'Two',
                                           full_name: 'Student Two' }
      let(:student_3) { FactoryGirl.create :user_profile,
                                           first_name: 'Student',
                                           last_name: 'Three',
                                           full_name: 'Student Three' }
      let(:student_4) { FactoryGirl.create :user_profile,
                                           first_name: 'Student',
                                           last_name: 'Four',
                                           full_name: 'Student Four' }

      before do
        allow(Tasks::Assistants::HomeworkAssistant).to receive(:k_ago_map).with(1) {
          [ [1,1] ]
        }

        SetupPerformanceReportData[course: course,
                                   teacher: teacher,
                                   students: [student_1, student_2, student_3, student_4],
                                   ecosystem: @ecosystem]
      end

      it 'should work on the happy path' do
        api_get :index, teacher_token, parameters: { id: course.id }

        expect(response).to have_http_status :success
        resp = response.body_as_hash
        binding.pry
        expect(resp).to include({
          period_id: course.periods.first.id.to_s,
          data_headings: [
            { title: 'Homework 2 task plan',
              plan_id: resp[0][:data_headings][0][:plan_id],
              type: 'homework',
              due_at: resp[0][:data_headings][0][:due_at],
              average: 54.16666666666667 },
            { title: 'Reading task plan',
              plan_id: resp[0][:data_headings][1][:plan_id],
              type: 'reading',
              due_at: resp[0][:data_headings][1][:due_at] },
            { title: 'Homework task plan',
              plan_id: resp[0][:data_headings][2][:plan_id],
              type: 'homework',
              due_at: resp[0][:data_headings][2][:due_at],
              average: 70.0 }
          ],
          students: [{
            name: 'Student One',
            first_name: 'Student',
            last_name: 'One',
            role: resp[0][:students][0][:role],
            data: [
              {
                type: 'homework',
                id: resp[0][:students][0][:data][0][:id],
                status: 'completed',
                exercise_count: 4,
                correct_exercise_count: 3,
                recovered_exercise_count: 0,
                due_at: resp[0][:students][0][:data][0][:due_at],
                last_worked_at: resp[0][:students][0][:data][0][:last_worked_at]
              },
              {
                type: 'reading',
                id: resp[0][:students][0][:data][1][:id],
                status: 'completed',
                due_at: resp[0][:students][0][:data][1][:due_at],
                last_worked_at: resp[0][:students][0][:data][1][:last_worked_at]
              },
              {
                type: 'homework',
                id: resp[0][:students][0][:data][2][:id],
                status: 'completed',
                exercise_count: 6,
                correct_exercise_count: 6,
                recovered_exercise_count: 0,
                due_at: resp[0][:students][0][:data][2][:due_at],
                last_worked_at: resp[0][:students][0][:data][2][:last_worked_at]
              }
            ]
          }, {
            name: 'Student Two',
            first_name: 'Student',
            last_name: 'Two',
            role: resp[0][:students][1][:role],
            data: [
              {
                type: 'homework',
                id: resp[0][:students][1][:data][0][:id],
                status: 'in_progress',
                exercise_count: 4,
                correct_exercise_count: 1,
                recovered_exercise_count: 0,
                due_at: resp[0][:students][1][:data][0][:due_at],
                last_worked_at: resp[0][:students][1][:data][0][:last_worked_at]
              },
              {
                type: 'reading',
                id: resp[0][:students][1][:data][1][:id],
                status: 'in_progress',
                due_at: resp[0][:students][1][:data][1][:due_at],
                last_worked_at: resp[0][:students][1][:data][1][:last_worked_at]
              },
              {
                type: 'homework',
                id: resp[0][:students][1][:data][2][:id],
                status: 'in_progress',
                exercise_count: 6,
                correct_exercise_count: 2,
                recovered_exercise_count: 0,
                due_at: resp[0][:students][1][:data][2][:due_at],
                last_worked_at: resp[0][:students][1][:data][2][:last_worked_at]
              }
            ]
          }]
        }, {
          period_id: course.periods.order(:id).last.id.to_s,
          data_headings: [
            { title: 'Homework 2 task plan',
              plan_id: resp[1][:data_headings][0][:plan_id],
              type: 'homework',
              due_at: resp[1][:data_headings][0][:due_at]
            },
            { title: 'Reading task plan',
              plan_id: resp[1][:data_headings][1][:plan_id],
              type: 'reading',
              due_at: resp[1][:data_headings][1][:due_at]
            },
            { title: 'Homework task plan',
              plan_id: resp[1][:data_headings][2][:plan_id],
              type: 'homework',
              due_at: resp[1][:data_headings][2][:due_at],
              average: 100.0
            }
          ],
          students: [{
            name: 'Student Four',
            first_name: 'Student',
            last_name: 'Four',
            role: resp[1][:students][0][:role],
            data: [
              {
                type: 'homework',
                id: resp[1][:students][0][:data][0][:id],
                status: 'not_started',
                exercise_count: 4,
                correct_exercise_count: 0,
                recovered_exercise_count: 0,
                due_at: resp[1][:students][0][:data][0][:due_at]
              },
              {
                type: 'reading',
                id: resp[1][:students][0][:data][1][:id],
                status: 'not_started',
                due_at: resp[1][:students][0][:data][1][:due_at]
              },
              {
                type: 'homework',
                id: resp[1][:students][0][:data][2][:id],
                status: 'not_started',
                exercise_count: 6,
                correct_exercise_count: 0,
                recovered_exercise_count: 0,
                due_at: resp[1][:students][0][:data][2][:due_at]
              }
            ]
          },
          {
            name: 'Student Three',
            first_name: 'Student',
            last_name: 'Three',
            role: resp[1][:students][1][:role],
            data: [
              {
                type: 'homework',
                id: resp[1][:students][1][:data][0][:id],
                status: 'not_started',
                exercise_count: 4,
                correct_exercise_count: 0,
                recovered_exercise_count: 0,
                due_at: resp[1][:students][1][:data][0][:due_at]
              },
              {
                type: 'reading',
                id: resp[1][:students][1][:data][1][:id],
                status: 'not_started',
                due_at: resp[1][:students][1][:data][1][:due_at]
              },
              {
                type: 'homework',
                id: resp[1][:students][1][:data][2][:id],
                status: 'completed',
                exercise_count: 6,
                correct_exercise_count: 6,
                recovered_exercise_count: 0,
                due_at: resp[1][:students][1][:data][2][:due_at],
                last_worked_at: resp[1][:students][1][:data][2][:last_worked_at]
              }
            ]
          }]
        })
      end

      it 'raises error for users not in the course' do
        expect {
          api_get :index, userless_token, parameters: { id: course.id }
        }.to raise_error StandardError
      end

      it 'raises error for students' do
        expect {
          api_get :index, student_1_token, parameters: { id: course.id }
        }.to raise_error SecurityTransgression
      end
    end
  end

  describe 'POST #export' do
    let(:teacher) { FactoryGirl.create :user_profile }
    let(:teacher_token) { FactoryGirl.create :doorkeeper_access_token,
                           resource_owner_id: teacher.id }

    before do
      AddUserAsCourseTeacher[course: course, user: teacher.entity_user]
    end

    context 'success' do
      after(:each) do
        Tasks::Models::PerformanceReportExport.all.each do |performance_report_export|
          performance_report_export.try(:export).try(:file).try(:delete)
        end
      end

      it 'returns 202 for authorized teachers' do
        api_post :export, teacher_token, parameters: { id: course.id }
        expect(response.status).to eq(202)
        expect(response.body_as_hash[:job]).to match(%r{/api/jobs/[a-z0-9-]+})
      end

      it 'returns the job path for the performance book export for authorized teachers' do
        api_post :export, teacher_token, parameters: { id: course.id }
        expect(response.body_as_hash[:job]).to match(%r{/jobs/[a-f0-9-]+})
      end
    end

    context 'failure' do
      it 'returns 403 unauthorized users' do
        unknown = FactoryGirl.create :user_profile
        unknown_token = FactoryGirl.create :doorkeeper_access_token,
                                           resource_owner_id: unknown.id

        expect {
          api_post :export, unknown_token, parameters: { id: course.id }
        }.to raise_error(SecurityTransgression)
      end

      it 'returns 404 for non-existent courses' do
        expect {
          api_post :export, teacher_token, parameters: { id: 'nope' }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'GET #exports' do
    let(:teacher) { FactoryGirl.create :user_profile }
    let(:teacher_token) { FactoryGirl.create :doorkeeper_access_token,
                           resource_owner_id: teacher.id }

    before(:each) do
      AddUserAsCourseTeacher[course: course, user: teacher.entity_user]
    end

    context 'success' do
      before(:each) do
        role = ChooseCourseRole[user: teacher.entity_user,
                                course: course,
                                allowed_role_type: :teacher]

        @export = Tempfile.open(['test_export', '.xls']) do |file|
          FactoryGirl.create(:performance_report_export, export: file, course: course, role: role)
        end
      end

      after(:each) do
        Tasks::Models::PerformanceReportExport.all.each do |performance_report_export|
          performance_report_export.try(:export).try(:file).try(:delete)
        end
      end

      it 'returns the filename, url, timestamp of all exports for the course' do
        api_get :exports, teacher_token, parameters: { id: course.id }

        expect(response.status).to eq(200)
        expect(response.body_as_hash.last[:filename]).not_to include('test_export')
        expect(response.body_as_hash.last[:filename]).to include('.xls')
        expect(response.body_as_hash.last[:url]).to eq(@export.url)
        expect(response.body_as_hash.last[:created_at]).not_to be_nil
      end
    end

    context 'failure' do
      it 'returns 403 for users who are not teachers of the course' do
        unknown = FactoryGirl.create :user_profile
        unknown_token = FactoryGirl.create :doorkeeper_access_token,
                                           resource_owner_id: unknown.id

        expect {
          api_get :exports, unknown_token, parameters: { id: course.id }
        }.to raise_error(SecurityTransgression)
      end

      it 'returns 404 for non-existent courses' do
        expect {
          api_get :exports, teacher_token, parameters: { id: 'nope' }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
