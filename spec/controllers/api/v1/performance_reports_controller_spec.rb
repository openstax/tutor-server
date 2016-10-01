require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Api::V1::PerformanceReportsController, type: :controller, api: true,
                                                      version: :v1, speed: :slow, vcr: VCR_OPTS do

  let(:course) { FactoryGirl.create :course_profile_course, :with_assistants }
  let(:period) { FactoryGirl.create :course_membership_period, course: course }

  context 'with book' do
    before(:all) do
      VCR.use_cassette("Api_V1_PerformanceReportsController/with_book", VCR_OPTS) do
        @ecosystem = FetchAndImportBookAndCreateEcosystem[
          book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b'
        ]
      end
    end

    before(:each) do
      CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: @ecosystem)
    end

    describe '#index' do
      let(:teacher) { FactoryGirl.create(:user) }
      let(:teacher_token) { FactoryGirl.create :doorkeeper_access_token,
                                               resource_owner_id: teacher.id }
      let(:student_1) { FactoryGirl.create(:user, first_name: 'Student',
                                                  last_name: 'One',
                                                  full_name: 'Student One') }
      let(:student_1_token) { FactoryGirl.create :doorkeeper_access_token,
                                resource_owner_id: student_1.id }

      let(:student_2) { FactoryGirl.create(:user, first_name: 'Student',
                                                  last_name: 'Two',
                                                  full_name: 'Student Two') }

      let(:student_3) { FactoryGirl.create(:user, first_name: 'Student',
                                                  last_name: 'Three',
                                                  full_name: 'Student Three') }

      let(:student_4) { FactoryGirl.create(:user, first_name: 'Student',
                                                  last_name: 'Four',
                                                  full_name: 'Student Four') }

      before do
        allow_any_instance_of(Tasks::Assistants::HomeworkAssistant).to(
          receive(:k_ago_map).with(1) { [ [1, 1] ] }
        )

        SetupPerformanceReportData[course: course,
                                   teacher: teacher,
                                   students: [student_1, student_2, student_3, student_4],
                                   ecosystem: @ecosystem]
      end

      it 'should work on the happy path' do
        Timecop.freeze(Time.current + 1.1.days) do
          api_get :index, teacher_token, parameters: { id: course.id }
        end

        expect(response).to have_http_status :success
        resp = response.body_as_hash

        expect(resp).to include({
          period_id: course.periods.first.id.to_s,
          overall_average_score: be_within(1e-6).of(2/3.0),
          data_headings: [
            { title: 'Homework 2 task plan',
              plan_id: resp[0][:data_headings][0][:plan_id],
              type: 'homework',
              due_at: resp[0][:data_headings][0][:due_at],
              completion_rate: 0.5 },
            { title: 'Reading task plan',
              plan_id: resp[0][:data_headings][1][:plan_id],
              type: 'reading',
              due_at: resp[0][:data_headings][1][:due_at],
              completion_rate: 0.5 },
            { title: 'Homework task plan',
              plan_id: resp[0][:data_headings][2][:plan_id],
              type: 'homework',
              due_at: resp[0][:data_headings][2][:due_at],
              average_score: be_within(1e-6).of(2/3.0),
              completion_rate: 0.5 }
          ],
          students: [{
            name: 'Student One',
            first_name: 'Student',
            last_name: 'One',
            role: resp[0][:students][0][:role],
            student_identifier: 'S1',
            average_score: 1.0,
            is_dropped: false,
            data: [
              {
                type: 'homework',
                id: resp[0][:students][0][:data][0][:id],
                status: 'completed',
                step_count: 4,
                completed_step_count: 4,
                completed_on_time_step_count: 4,
                completed_accepted_late_step_count: 0,
                exercise_count: 4,
                completed_exercise_count: 4,
                completed_on_time_exercise_count: 4,
                completed_accepted_late_exercise_count: 0,
                correct_exercise_count: 3,
                correct_on_time_exercise_count: 3,
                correct_accepted_late_exercise_count: 0,
                score: 0.75,
                recovered_exercise_count: 0,
                due_at: resp[0][:students][0][:data][0][:due_at],
                last_worked_at: resp[0][:students][0][:data][0][:last_worked_at],
                is_late_work_accepted: false,
                is_included_in_averages: false
              },
              {
                type: 'reading',
                id: resp[0][:students][0][:data][1][:id],
                status: 'completed',
                step_count: 8,
                completed_step_count: 8,
                completed_on_time_step_count: 8,
                completed_accepted_late_step_count: 0,
                exercise_count: 6,
                completed_exercise_count: 6,
                completed_on_time_exercise_count: 6,
                completed_accepted_late_exercise_count: 0,
                correct_exercise_count: 0,
                correct_on_time_exercise_count: 0,
                correct_accepted_late_exercise_count: 0,
                score: 0.0,
                recovered_exercise_count: 0,
                due_at: resp[0][:students][0][:data][1][:due_at],
                last_worked_at: resp[0][:students][0][:data][1][:last_worked_at],
                is_late_work_accepted: false,
                is_included_in_averages: false
              },
              {
                type: 'homework',
                id: resp[0][:students][0][:data][2][:id],
                status: 'completed',
                step_count: 6,
                completed_step_count: 6,
                completed_on_time_step_count: 6,
                completed_accepted_late_step_count: 0,
                exercise_count: 6,
                completed_exercise_count: 6,
                completed_on_time_exercise_count: 6,
                completed_accepted_late_exercise_count: 0,
                correct_exercise_count: 6,
                correct_on_time_exercise_count: 6,
                correct_accepted_late_exercise_count: 0,
                score: 1.0,
                recovered_exercise_count: 0,
                due_at: resp[0][:students][0][:data][2][:due_at],
                last_worked_at: resp[0][:students][0][:data][2][:last_worked_at],
                is_late_work_accepted: false,
                is_included_in_averages: true
              }
            ]
          }, {
            name: 'Student Two',
            first_name: 'Student',
            last_name: 'Two',
            role: resp[0][:students][1][:role],
            student_identifier: 'S2',
            average_score: be_within(1e-6).of(1/3.0),
            is_dropped: false,
            data: [
              {
                type: 'homework',
                id: resp[0][:students][1][:data][0][:id],
                status: 'in_progress',
                step_count: 4,
                completed_step_count: 1,
                completed_on_time_step_count: 1,
                completed_accepted_late_step_count: 0,
                exercise_count: 4,
                completed_exercise_count: 1,
                completed_on_time_exercise_count: 1,
                completed_accepted_late_exercise_count: 0,
                correct_exercise_count: 1,
                correct_on_time_exercise_count: 1,
                correct_accepted_late_exercise_count: 0,
                score: 0.25,
                recovered_exercise_count: 0,
                due_at: resp[0][:students][1][:data][0][:due_at],
                last_worked_at: resp[0][:students][1][:data][0][:last_worked_at],
                is_late_work_accepted: false,
                is_included_in_averages: false
              },
              {
                type: 'reading',
                id: resp[0][:students][1][:data][1][:id],
                status: 'in_progress',
                step_count: 8,
                completed_step_count: 1,
                completed_on_time_step_count: 1,
                completed_accepted_late_step_count: 0,
                exercise_count: 6,
                completed_exercise_count: 0,
                completed_on_time_exercise_count: 0,
                completed_accepted_late_exercise_count: 0,
                correct_exercise_count: 0,
                correct_on_time_exercise_count: 0,
                correct_accepted_late_exercise_count: 0,
                score: 0.0,
                recovered_exercise_count: 0,
                due_at: resp[0][:students][1][:data][1][:due_at],
                last_worked_at: resp[0][:students][1][:data][1][:last_worked_at],
                is_late_work_accepted: false,
                is_included_in_averages: false
              },
              {
                type: 'homework',
                id: resp[0][:students][1][:data][2][:id],
                status: 'in_progress',
                step_count: 6,
                completed_step_count: 4,
                completed_on_time_step_count: 4,
                completed_accepted_late_step_count: 0,
                exercise_count: 6,
                completed_exercise_count: 4,
                completed_on_time_exercise_count: 4,
                completed_accepted_late_exercise_count: 0,
                correct_exercise_count: 2,
                correct_on_time_exercise_count: 2,
                correct_accepted_late_exercise_count: 0,
                score: be_within(1e-6).of(1/3.0),
                recovered_exercise_count: 0,
                due_at: resp[0][:students][1][:data][2][:due_at],
                last_worked_at: resp[0][:students][1][:data][2][:last_worked_at],
                is_late_work_accepted: false,
                is_included_in_averages: true
              }
            ]
          }]
        }, {
          period_id: course.periods.order(:id).last.id.to_s,
          overall_average_score: 0.5,
          data_headings: [
            { title: 'Homework 2 task plan',
              plan_id: resp[1][:data_headings][0][:plan_id],
              type: 'homework',
              due_at: resp[1][:data_headings][0][:due_at],
              completion_rate: 0.0
            },
            { title: 'Reading task plan',
              plan_id: resp[1][:data_headings][1][:plan_id],
              type: 'reading',
              due_at: resp[1][:data_headings][1][:due_at],
              completion_rate: 0.0
            },
            { title: 'Homework task plan',
              plan_id: resp[1][:data_headings][2][:plan_id],
              type: 'homework',
              due_at: resp[1][:data_headings][2][:due_at],
              average_score: 0.5,
              completion_rate: 0.5
            }
          ],
          students: [{
            name: 'Student Four',
            first_name: 'Student',
            last_name: 'Four',
            role: resp[1][:students][0][:role],
            student_identifier: 'S4',
            average_score: 0.0,
            is_dropped: false,
            data: [
              {
                type: 'homework',
                id: resp[1][:students][0][:data][0][:id],
                status: 'not_started',
                step_count: 4,
                completed_step_count: 0,
                completed_on_time_step_count: 0,
                completed_accepted_late_step_count: 0,
                exercise_count: 4,
                completed_exercise_count: 0,
                completed_on_time_exercise_count: 0,
                completed_accepted_late_exercise_count: 0,
                correct_exercise_count: 0,
                correct_on_time_exercise_count: 0,
                correct_accepted_late_exercise_count: 0,
                score: 0.0,
                recovered_exercise_count: 0,
                due_at: resp[1][:students][0][:data][0][:due_at],
                is_late_work_accepted: false,
                is_included_in_averages: false
              },
              {
                type: 'reading',
                id: resp[1][:students][0][:data][1][:id],
                status: 'not_started',
                step_count: 8,
                completed_step_count: 0,
                completed_on_time_step_count: 0,
                completed_accepted_late_step_count: 0,
                exercise_count: 6,
                completed_exercise_count: 0,
                completed_on_time_exercise_count: 0,
                completed_accepted_late_exercise_count: 0,
                correct_exercise_count: 0,
                correct_on_time_exercise_count: 0,
                correct_accepted_late_exercise_count: 0,
                score: 0.0,
                recovered_exercise_count: 0,
                due_at: resp[1][:students][0][:data][1][:due_at],
                is_late_work_accepted: false,
                is_included_in_averages: false
              },
              {
                type: 'homework',
                id: resp[1][:students][0][:data][2][:id],
                status: 'not_started',
                step_count: 6,
                completed_step_count: 0,
                completed_on_time_step_count: 0,
                completed_accepted_late_step_count: 0,
                exercise_count: 6,
                completed_exercise_count: 0,
                completed_on_time_exercise_count: 0,
                completed_accepted_late_exercise_count: 0,
                correct_exercise_count: 0,
                correct_on_time_exercise_count: 0,
                correct_accepted_late_exercise_count: 0,
                score: 0.0,
                recovered_exercise_count: 0,
                due_at: resp[1][:students][0][:data][2][:due_at],
                is_late_work_accepted: false,
                is_included_in_averages: true
              }
            ]
          },
          {
            name: 'Student Three',
            first_name: 'Student',
            last_name: 'Three',
            role: resp[1][:students][1][:role],
            student_identifier: 'S3',
            average_score: 1.0,
            is_dropped: false,
            data: [
              {
                type: 'homework',
                id: resp[1][:students][1][:data][0][:id],
                status: 'not_started',
                step_count: 4,
                completed_step_count: 0,
                completed_on_time_step_count: 0,
                completed_accepted_late_step_count: 0,
                exercise_count: 4,
                completed_exercise_count: 0,
                completed_on_time_exercise_count: 0,
                completed_accepted_late_exercise_count: 0,
                correct_exercise_count: 0,
                correct_on_time_exercise_count: 0,
                correct_accepted_late_exercise_count: 0,
                score: 0.0,
                recovered_exercise_count: 0,
                due_at: resp[1][:students][1][:data][0][:due_at],
                is_late_work_accepted: false,
                is_included_in_averages: false
              },
              {
                type: 'reading',
                id: resp[1][:students][1][:data][1][:id],
                status: 'not_started',
                step_count: 8,
                completed_step_count: 0,
                completed_on_time_step_count: 0,
                completed_accepted_late_step_count: 0,
                exercise_count: 6,
                completed_exercise_count: 0,
                completed_on_time_exercise_count: 0,
                completed_accepted_late_exercise_count: 0,
                correct_exercise_count: 0,
                correct_on_time_exercise_count: 0,
                correct_accepted_late_exercise_count: 0,
                score: 0.0,
                recovered_exercise_count: 0,
                due_at: resp[1][:students][1][:data][1][:due_at],
                is_late_work_accepted: false,
                is_included_in_averages: false
              },
              {
                type: 'homework',
                id: resp[1][:students][1][:data][2][:id],
                status: 'completed',
                step_count: 6,
                completed_step_count: 6,
                completed_on_time_step_count: 6,
                completed_accepted_late_step_count: 0,
                exercise_count: 6,
                completed_exercise_count: 6,
                completed_on_time_exercise_count: 6,
                completed_accepted_late_exercise_count: 0,
                correct_exercise_count: 6,
                correct_on_time_exercise_count: 6,
                correct_accepted_late_exercise_count: 0,
                score: 1.0,
                recovered_exercise_count: 0,
                due_at: resp[1][:students][1][:data][2][:due_at],
                last_worked_at: resp[1][:students][1][:data][2][:last_worked_at],
                is_late_work_accepted: false,
                is_included_in_averages: true
              }
            ]
          }]
        })
      end

      it 'works after a student has moved period' do
        period_2 = course.periods.order(:id).last
        role = GetUserCourseRoles[user: student_1, course: course].first
        student = CourseMembership::Models::Student.find_by(role: role)
        MoveStudent.call(period: period_2, student: student)

        Timecop.freeze(Time.current + 1.1.days) do
          api_get :index, teacher_token, parameters: { id: course.id }
        end

        expect(response).to have_http_status :success
        resp = response.body_as_hash

        # No need to retest the entire response, just spot check some things that
        # should change when the student moves

        # period 1 no longer has an average score in the data headings (complete tasks
        # moved to period 2; on the other hand, period 2 now has average scores where
        # it didn't before
        expect(resp[0][:data_headings][0]).not_to have_key(:average_score)
        expect(resp[1][:overall_average_score]).to be_within(1e-6).of(2/3.0)
        expect(resp[1][:data_headings][2][:average_score]).to be_within(1e-6).of(2/3.0)

        # There should now be 3 students in period 2 whereas before there were 2
        expect(resp[1][:students].length).to eq 3
      end

      it 'returns 403 for users not in the course' do
        unknown = FactoryGirl.create(:user)
        unknown_token = FactoryGirl.create :doorkeeper_access_token,
                                           resource_owner_id: unknown.id

        expect {
          api_get :index, unknown_token, parameters: { id: course.id }
        }.to raise_error(SecurityTransgression)
      end

      it 'returns 403 for students' do
        expect {
          api_get :index, student_1_token, parameters: { id: course.id }
        }.to raise_error SecurityTransgression
      end

      it 'marks dropped students and excludes them from averages' do
        CourseMembership::InactivateStudent.call(student: student_2.to_model.roles.first.student)

        Timecop.freeze(Time.current + 1.1.days) do
          api_get :index, teacher_token, parameters: { id: course.id }
        end

        expect(response.body_as_hash[0]).to include(
          overall_average_score: 1.0,
          students: a_collection_including(a_hash_including(name: 'Student Two', is_dropped: true))
        )
      end
    end
  end

  describe 'POST #export' do
    let(:teacher) { FactoryGirl.create(:user) }
    let(:teacher_token) { FactoryGirl.create :doorkeeper_access_token,
                           resource_owner_id: teacher.id }

    before do
      AddUserAsCourseTeacher[course: course, user: teacher]
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

      it 'does not blow up when the period name is more than 31 characters' do
        period.to_model.update_attributes(name: 'a' * 50)
        api_post :export, teacher_token, parameters: { id: course.id }
        expect(response.status).to eq(202)
      end

      it 'does not blow up when the period name has invalid worksheet characters' do
        period.to_model.update_attributes(name: '[p: 1 \/ 2? *]')
        api_post :export, teacher_token, parameters: { id: course.id }
        expect(response.status).to eq(202)
      end

      it 'does not blow up when period names collide for the first 31 characters' do
        period.to_model.update_attributes(name: 'Super duper long period name number 1')
        FactoryGirl.create :course_membership_period, course: course,
                                                      name: 'Super duper long period name number 2'
        api_post :export, teacher_token, parameters: { id: course.id }
        expect(response.status).to eq(202)
      end
    end

    context 'failure' do
      it 'returns 403 for students' do
        student = FactoryGirl.create(:user)
        student_token = FactoryGirl.create(:doorkeeper_access_token,
                                           resource_owner_id: student.id)
        AddUserAsPeriodStudent[period: period, user: student]

        expect {
          api_post :export, student_token, parameters: { id: course.id }
        }.to raise_error(SecurityTransgression)
      end

      it 'returns 403 unauthorized users' do
        unknown = FactoryGirl.create(:user)
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
    let(:teacher) { FactoryGirl.create(:user) }
    let(:teacher_token) { FactoryGirl.create :doorkeeper_access_token,
                           resource_owner_id: teacher.id }

    before(:each) do
      AddUserAsCourseTeacher[course: course, user: teacher]
    end

    context 'success' do
      before(:each) do
        role = ChooseCourseRole[user: teacher, course: course, allowed_role_type: :teacher]

        @export = Tempfile.open(['test_export', '.xls']) do |file|
          FactoryGirl.create(:tasks_performance_report_export,
                             export: file, course: course, role: role)
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
      it 'returns 403 for students' do
        student = FactoryGirl.create(:user)
        student_token = FactoryGirl.create(:doorkeeper_access_token,
                                           resource_owner_id: student.id)
        AddUserAsPeriodStudent[period: period, user: student]

        expect {
          api_get :export, student_token, parameters: { id: course.id }
        }.to raise_error(SecurityTransgression)
      end

      it 'returns 403 for users who are not teachers of the course' do
        unknown = FactoryGirl.create(:user)
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
