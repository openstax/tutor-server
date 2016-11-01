require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Api::V1::CoursesController, type: :controller, api: true,
                                           version: :v1, speed: :slow, vcr: VCR_OPTS do

  let(:user_1)         { FactoryGirl.create(:user) }
  let(:user_1_token)   { FactoryGirl.create :doorkeeper_access_token,
                                            resource_owner_id: user_1.id }

  let(:user_2)         { FactoryGirl.create(:user) }
  let(:user_2_token)   { FactoryGirl.create :doorkeeper_access_token,
                                            resource_owner_id: user_2.id }

  let(:userless_token) { FactoryGirl.create :doorkeeper_access_token }

  let(:course)         { FactoryGirl.create :course_profile_course, name: 'Physics 101' }
  let!(:period)        { FactoryGirl.create :course_membership_period, course: course }

  let(:book)           { FactoryGirl.create(:content_book, :standard_contents_1) }
  let(:ecosystem)      do
    strategy = Content::Strategies::Direct::Ecosystem.new(book.ecosystem.reload)
    Content::Ecosystem.new(strategy: strategy)
  end

  def add_book_to_course(course:)
    CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: ecosystem)

    { book: book, ecosystem: ecosystem }
  end

  context '#index' do
    let(:roles)          { Role::GetUserRoles.call(user_1).outputs.roles }
    let(:teacher)        { roles.select(&:teacher?).first }
    let(:student)        { roles.select(&:student?).first }
    let!(:zeroth_period) do
      FactoryGirl.create :course_membership_period, course: course, name: '0th'
    end

    before { zeroth_period.to_model.destroy! }

    context 'anonymous user' do
      it 'raises SecurityTransgression' do
        expect{ api_get :index, nil }.to raise_error(SecurityTransgression)
      end
    end

    context 'user is not in the course' do
      it 'returns nothing' do
        api_get :index, user_1_token
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to eq([])
      end
    end

    context 'user is a teacher or student in the course' do
      before do
        AddUserAsCourseTeacher.call(course: course, user: user_1)
      end

      it 'includes periods (even archived) and ecosystem_id for the course' do
        ecosystem = add_book_to_course(course: course)[:ecosystem]

        api_get :index, user_1_token

        expect(response.body_as_hash.first).to match({
          id: course.id.to_s,
          name: course.name,
          term: course.term,
          year: course.year,
          num_sections: course.num_sections,
          starts_at: a_kind_of(String),
          ends_at: a_kind_of(String),
          is_active: true,
          is_college: true,
          is_concept_coach: false,
          offering_id: course.offering.id.to_s,
          appearance_code: course.offering.appearance_code,
          salesforce_book_name: course.offering.salesforce_book_name,
          webview_url: course.offering.webview_url,
          book_pdf_url: course.offering.pdf_url,
          time_zone: course.time_zone.name,
          default_open_time: '00:01',
          default_due_time: '07:00',
          ecosystem_id: ecosystem.id.to_s,
          roles: [{ id: teacher.id.to_s, type: 'teacher' }],
          periods: [{ id: zeroth_period.id.to_s,
                      name: zeroth_period.name,
                      enrollment_code: zeroth_period.enrollment_code,
                      enrollment_url: a_string_matching(
                        /enroll\/#{zeroth_period.enrollment_code_for_url}/
                      ),
                      default_open_time: '00:01',
                      default_due_time: '07:00',
                      is_archived: true,
                      archived_at: DateTimeUtilities.to_api_s(zeroth_period.deleted_at),
                      teacher_student_role_id: zeroth_period.entity_teacher_student_role_id.to_s },
                    { id: period.id.to_s,
                      name: period.name,
                      enrollment_code: period.enrollment_code,
                      enrollment_url: a_string_matching(
                        /enroll\/#{period.enrollment_code_for_url}/
                      ),
                      default_open_time: '00:01',
                      default_due_time: '07:00',
                      is_archived: false,
                      teacher_student_role_id: period.entity_teacher_student_role_id.to_s }],
          students: []
        })
      end
    end

    context 'user is a teacher' do
      before { AddUserAsCourseTeacher.call(course: course, user: user_1) }

      it 'returns the teacher roles with the course' do
        api_get :index, user_1_token
        expect(response.body_as_hash.first).to match a_hash_including(
          roles: a_collection_containing_exactly({ id: teacher.id.to_s, type: 'teacher' })
        )
      end
    end

    context 'user is a student' do
      before { AddUserAsPeriodStudent.call(period: period, user: user_1) }

      it 'returns the student roles with the course' do
        api_get :index, user_1_token
        expect(response.body_as_hash.first).to match a_hash_including(
          roles: a_collection_containing_exactly({ id: student.id.to_s, type: 'student' }),
        )
      end
    end

    context 'user is both a teacher and student' do
      before do
        AddUserAsPeriodStudent.call(period: period, user: user_1)
        AddUserAsCourseTeacher.call(course: course, user: user_1)
      end

      it 'returns both roles with the course' do
        api_get :index, user_1_token
        expect(response.body_as_hash.first).to match a_hash_including(
          roles: a_collection_containing_exactly({ id: student.id.to_s, type: 'student', },
                                                 { id: teacher.id.to_s, type: 'teacher' }),
        )
      end
    end
  end

  context '#create' do
    let(:term)             { CourseProfile::Models::Course.terms.keys.sample }
    let(:year)             { Time.current.year }
    let(:catalog_offering) { FactoryGirl.create :catalog_offering }
    let(:num_sections)     { 2 }

    let(:valid_body) do
      {
        name: 'A Course',
        term: term,
        year: year,
        is_college: true,
        num_sections: num_sections,
        offering_id: catalog_offering.id
      }.to_json
    end

    context 'anonymous user' do
      it 'raises SecurityTransgression' do
        expect{ api_post :create, nil, raw_post_data: valid_body }.to(
          raise_error(SecurityTransgression)
        )
      end
    end

    context 'normal user' do
      it 'raises SecurityTransgression' do
        expect{ api_post :create, user_1_token, raw_post_data: valid_body }.to(
          raise_error(SecurityTransgression)
        )
      end
    end

    context 'verified faculty' do
      let(:expected_response) do
        {
          id: a_kind_of(String),
          name: 'A Course',
          term: term,
          year: year,
          starts_at: a_kind_of(String),
          ends_at: a_kind_of(String),
          is_active: be_in([true, false]),
          is_college: true,
          is_concept_coach: false,
          num_sections: num_sections,
          offering_id: catalog_offering.id.to_s,
          appearance_code: catalog_offering.appearance_code,
          salesforce_book_name: catalog_offering.salesforce_book_name,
          webview_url: catalog_offering.webview_url,
          book_pdf_url: catalog_offering.pdf_url,
          time_zone: 'Central Time (US & Canada)',
          default_due_time: '07:00',
          default_open_time: '00:01',
          periods: [a_kind_of(Hash)]*num_sections,
          students: [],
          ecosystem_id: catalog_offering.content_ecosystem_id.to_s,
          roles: [a_kind_of(Hash)]
        }
      end

      before { user_1.account.update_attribute :faculty_status, :confirmed_faculty }

      it 'creates a new course for the faculty if all required attributes are specified' do
        expect{ api_post :create, user_1_token, raw_post_data: valid_body }.to(
          change{ CourseProfile::Models::Course.count }.by(1)
        )
        expect(response).to have_http_status :success
        expect(response.body_as_hash).to match expected_response
      end

      it 'makes the requesting faculty a teacher in the new course' do
        expect{ api_post :create, user_1_token, raw_post_data: valid_body }.to(
          change{ CourseMembership::Models::Teacher.count }.by(1)
        )
        expect(response).to have_http_status :success
        course = CourseProfile::Models::Course.order(:created_at).last
        expect(UserIsCourseTeacher[user: user_1, course: course]).to eq true
      end

      it 'returns errors if required attributes are not specified' do
        expect{ api_post :create, user_1_token }.not_to(
          change{ CourseProfile::Models::Course.count }
        )
        expect(response).to have_http_status :unprocessable_entity
        expect(response.body_as_hash[:status]).to eq 422
        [:name, :term, :year, :is_college, :catalog_offering_id].each do |required_attr|
          expect(response.body_as_hash[:errors]).to include(
            {code: "missing_attribute", message: "The #{required_attr} attribute must be provided"}
          )
        end
      end
    end
  end

  context '#show' do
    let(:roles)          { Role::GetUserRoles.call(user_1).outputs.roles }
    let(:teacher)        { roles.select(&:teacher?).first }
    let(:student)        { roles.select(&:student?).first }
    let!(:zeroth_period) { FactoryGirl.create :course_membership_period, course: course }

    context 'course does not exist' do
      it 'raises RecordNotFound' do
        expect{ api_get :show, nil, parameters: { id: -1 } }.to(
          raise_error(ActiveRecord::RecordNotFound)
        )
      end
    end

    context 'anonymous user' do
      it 'raises SecurityTransgression' do
        expect{ api_get :show, nil, parameters: { id: course.id } }.to(
          raise_error(SecurityTransgression)
        )
      end
    end

    context 'user is not in the course' do
      it 'raises SecurityTransgression' do
        expect{ api_get :show, user_1_token, parameters: { id: course.id } }.to(
          raise_error(SecurityTransgression)
        )
      end
    end

    context 'user is a teacher' do
      let!(:teacher) { AddUserAsCourseTeacher.call(course: course, user: user_1).outputs.role }

      it 'returns the teacher roles with the course' do
        api_get :show, user_1_token, parameters: { id: course.id }
        expect(response.body_as_hash).to match a_hash_including(
          roles: a_collection_containing_exactly({ id: teacher.id.to_s, type: 'teacher' }),
        )
      end
    end

    context 'user is a student' do
      let!(:student) { AddUserAsPeriodStudent.call(period: period, user: user_1).outputs.role }

      it 'returns the student roles with the course' do
        api_get :show, user_1_token, parameters: { id: course.id }
        expect(response.body_as_hash).to match a_hash_including(
          roles: a_collection_containing_exactly({ id: student.id.to_s, type: 'student' }),
        )
      end
    end

    context 'user is both a teacher and student' do
      let!(:student) { AddUserAsPeriodStudent.call(period: period, user: user_1).outputs.role }
      let!(:teacher) { AddUserAsCourseTeacher.call(course: course, user: user_1).outputs.role }

      it 'returns both roles with the course' do
        api_get :show, user_1_token, parameters: { id: course.id }
        expect(response.body_as_hash).to match a_hash_including(
          roles: a_collection_containing_exactly({ id: student.id.to_s, type: 'student' },
                                                 { id: teacher.id.to_s, type: 'teacher' }),
        )
      end
    end
  end

  context '#update' do
    context 'anonymous user' do
      it 'raises SecurityTransgression' do
        expect {
          api_patch :update, nil, parameters: { id: course.id },
                                  raw_post_data: { name: 'Renamed' }.to_json
        }.to raise_error(SecurityTransgression)
        expect(course.reload.name).to eq 'Physics 101'
      end
    end

    context 'user is a student' do
      before do
        AddUserAsPeriodStudent.call(user: user_1, period: period)
      end

      it 'raises SecurityTrangression' do
        expect {
          api_patch :update, user_1_token, parameters: { id: course.id },
                                           raw_post_data: { name: 'Renamed' }.to_json
        }.to raise_error(SecurityTransgression)
        expect(course.reload.name).to eq 'Physics 101'
      end
    end

    context 'user is a teacher' do
      before do
        AddUserAsCourseTeacher.call(user: user_1, course: course)
      end

      it 'renames the course' do
        api_patch :update, user_1_token, parameters: { id: course.id },
                                         raw_post_data: { name: 'Renamed' }.to_json
        expect(course.reload.name).to eq 'Renamed'
        expect(course.time_zone.name).to eq 'Central Time (US & Canada)'
        expect(response.body_as_hash[:name]).to eq 'Renamed'
        expect(response.body_as_hash[:time_zone]).to eq 'Central Time (US & Canada)'
      end

      it 'updates the time_zone' do
        opens_at_str = '2016-04-26 17:15:00'
        due_at_str = '2016-05-03 17:15:00'
        time_zone = ActiveSupport::TimeZone['Central Time (US & Canada)']
        opens_at = time_zone.parse(opens_at_str)
        due_at = time_zone.parse(due_at_str)

        task_plan = FactoryGirl.build :tasks_task_plan, owner: course, num_tasking_plans: 0
        tasking_plan = FactoryGirl.create :tasks_tasking_plan, task_plan: task_plan,
                                                               opens_at: opens_at_str,
                                                               due_at: due_at_str

        expect(tasking_plan.opens_at).to eq(opens_at)
        expect(tasking_plan.due_at).to eq(due_at)

        course_name = course.name
        api_patch :update, user_1_token, parameters: { id: course.id },
                                         raw_post_data: { name: course_name,
                                                          time_zone: 'Edinburgh' }.to_json
        expect(course.reload.name).to eq course_name
        expect(course.time_zone.name).to eq 'Edinburgh'
        expect(response.body_as_hash[:name]).to eq course_name
        expect(response.body_as_hash[:time_zone]).to eq 'Edinburgh'

        Time.zone = 'Edinburgh'
        new_opens_at = Time.zone.parse(opens_at_str)
        new_due_at = Time.zone.parse(due_at_str)

        expect(tasking_plan.reload.opens_at).to_not eq(opens_at)
        expect(tasking_plan.opens_at).to eq(new_opens_at)
        expect(tasking_plan.due_at).to_not eq(due_at)
        expect(tasking_plan.due_at).to eq(new_due_at)
      end

      it 'updates the default open time' do
        course_name = course.name
        api_patch :update, user_1_token, parameters: { id: course.id },
                                         raw_post_data: { default_open_time: '01:02' }.to_json
        expect(course.reload.name).to eq course_name
        expect(course.time_zone.name).to eq 'Central Time (US & Canada)'
        expect(course.reload.default_open_time).to eq '01:02'
        expect(response.body_as_hash[:name]).to eq course_name
        expect(response.body_as_hash[:time_zone]).to eq 'Central Time (US & Canada)'
        expect(response.body_as_hash[:default_open_time]).to eq '01:02'
      end

      it 'freaks if the default open time is in a bad format' do
        expect {
          api_patch :update, user_1_token,
                    parameters: { id: course.id },
                    raw_post_data: { default_open_time: '1pm' }.to_json
        }.not_to change{ course.reload.default_open_time }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'updates the default due time' do
        course_name = course.name
        api_patch :update, user_1_token, parameters: { id: course.id },
                                         raw_post_data: { default_due_time: '02:02' }.to_json
        expect(course.reload.name).to eq course_name
        expect(course.time_zone.name).to eq 'Central Time (US & Canada)'
        expect(course.reload.default_due_time).to eq '02:02'
        expect(response.body_as_hash[:name]).to eq course_name
        expect(response.body_as_hash[:time_zone]).to eq 'Central Time (US & Canada)'
        expect(response.body_as_hash[:default_due_time]).to eq '02:02'
      end

      it 'freaks if the default due time is in a bad format' do
        expect {
          api_patch :update, user_1_token,
                    parameters: { id: course.id },
                    raw_post_data: { default_due_time: '1pm' }.to_json
        }.not_to change{ course.reload.default_open_time }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'updates is_college' do
        expect(course.is_college).to eq true
        api_patch :update, user_1_token,
                  parameters: { id: course.id },
                  raw_post_data: { is_college: false }.to_json
        expect(course.reload.is_college).to eq false
      end
    end
  end

  context '#dashboard' do
    let(:student_user)    { FactoryGirl.create(:user) }
    let!(:student_role)   { AddUserAsPeriodStudent[user: student_user, period: period] }
    let(:student_token)   { FactoryGirl.create :doorkeeper_access_token,
                                               resource_owner_id: student_user.id }

    let(:teacher_user)    { FactoryGirl.create(:user, first_name: 'Bob',
                                                      last_name: 'Newhart',
                                                      full_name: 'Bob Newhart') }
    let!(:teacher_role)   { AddUserAsCourseTeacher[user: teacher_user, course: course] }
    let(:teacher_token)   { FactoryGirl.create :doorkeeper_access_token,
                                               resource_owner_id: teacher_user.id }

    let(:time_zone)       { course.time_zone.to_tz }
    let!(:reading_task)   { FactoryGirl.create(:tasks_task,
                                               task_type: :reading,
                                               opens_at: time_zone.now - 1.week,
                                               due_at: time_zone.now,
                                               step_types: [:tasks_tasked_reading,
                                                            :tasks_tasked_exercise,
                                                            :tasks_tasked_exercise],
                                               tasked_to: student_role)}

    let!(:hw1_task)   { FactoryGirl.create(:tasks_task,
                                           task_type: :homework,
                                           opens_at: time_zone.now - 1.week,
                                           due_at: time_zone.now,
                                           step_types: [:tasks_tasked_exercise,
                                                        :tasks_tasked_exercise,
                                                        :tasks_tasked_exercise],
                                           tasked_to: student_role)}

    let!(:hw2_task)   { FactoryGirl.create(:tasks_task,
                                           task_type: :homework,
                                           opens_at: time_zone.now - 1.week,
                                           due_at: time_zone.now,
                                           step_types: [:tasks_tasked_exercise,
                                                        :tasks_tasked_exercise,
                                                        :tasks_tasked_exercise],
                                           tasked_to: student_role)}

    let!(:hw3_task)   { FactoryGirl.create(:tasks_task,
                                           task_type: :homework,
                                           opens_at: time_zone.now - 1.week,
                                           due_at: time_zone.now + 2.weeks,
                                           step_types: [:tasks_tasked_exercise,
                                                        :tasks_tasked_exercise,
                                                        :tasks_tasked_exercise],
                                           tasked_to: student_role)}

    let!(:plan) { FactoryGirl.create(:tasks_task_plan, owner: course,
                                                       published_at: time_zone.now - 1.week)}

    context 'anonymous' do
      it 'raises SecurityTransgression if user is anonymous or not in course' do
        expect {
          api_get :dashboard, nil, parameters: { id: course.id }
        }.to raise_error(SecurityTransgression)

        expect {
          api_get :dashboard, user_1_token, parameters: { id: course.id }
        }.to raise_error(SecurityTransgression)
      end
    end

    context 'student' do
      it 'returns an error if the course is a CC course' do
        course.update_attribute(:is_concept_coach, true)
        api_get :dashboard, student_token, parameters: {id: course.id}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'cc_course'
      end

      it "works without a role specified" do
        Demo::AnswerExercise[task_step: hw1_task.task_steps[0], is_correct: true]
        Demo::AnswerExercise[task_step: hw1_task.task_steps[2], is_correct: false]

        Demo::AnswerExercise[task_step: hw2_task.task_steps[0], is_correct: true]
        Demo::AnswerExercise[task_step: hw2_task.task_steps[1], is_correct: true]
        Demo::AnswerExercise[task_step: hw2_task.task_steps[2], is_correct: false]

        Demo::AnswerExercise[task_step: hw3_task.task_steps[0], is_correct: false]
        Demo::AnswerExercise[task_step: hw3_task.task_steps[1], is_correct: false]
        Demo::AnswerExercise[task_step: hw3_task.task_steps[2], is_correct: false]

        api_get :dashboard, student_token, parameters: {id: course.id}

        expect(HashWithIndifferentAccess[response.body_as_hash]).to include(

          "tasks" => a_collection_including(
            a_hash_including(
              "id" => reading_task.id.to_s,
              "title" => reading_task.title,
              "opens_at" => be_kind_of(String),
              "due_at" => be_kind_of(String),
              "type" => 'reading',
              "complete" => false,
              "exercise_count" => 2,
              "complete_exercise_count" => 0
            ),
            a_hash_including(
              "id" => hw1_task.id.to_s,
              "title" => hw1_task.title,
              "opens_at" => be_kind_of(String),
              "due_at" => be_kind_of(String),
              "type" => 'homework',
              "complete" => false,
              "exercise_count" => 3,
              "complete_exercise_count" => 2
            ),
            a_hash_including(
              "id" => hw2_task.id.to_s,
              "title" => hw2_task.title,
              "opens_at" => be_kind_of(String),
              "due_at" => be_kind_of(String),
              "type" => 'homework',
              "complete" => true,
              "exercise_count" => 3,
              "complete_exercise_count" => 3,
              "correct_exercise_count" => 2
            ),
            a_hash_including(
              "id" => hw3_task.id.to_s,
              "title" => hw3_task.title,
              "opens_at" => be_kind_of(String),
              "due_at" => be_kind_of(String),
              "type" => 'homework',
              "complete" => true,
              "exercise_count" => 3,
              "complete_exercise_count" => 3,
            ),
          ),
          "role" => {
            "id" => student_role.id.to_s,
            "type" => 'student'
          },
          "course" => {
            "name" => 'Physics 101',
            "teachers" => [
              { 'id' => teacher_role.teacher.id.to_s,
                'role_id' => teacher_role.id.to_s,
                'first_name' => 'Bob',
                'last_name' => 'Newhart' }
            ]
          }
        )
      end

      it "allows the start_at and end_at dates to be specified" do
        api_get :dashboard, student_token, parameters: {
          id: course.id, start_at: time_zone.now + 1.day, end_at: time_zone.now + 1.week
        }

        expect(response.body_as_hash[:tasks].size).to eq 1
      end

      it "allows the start_at date to be specified alone" do
        api_get :dashboard, student_token, parameters: {
          id: course.id, start_at: time_zone.now + 1.day
        }

        expect(response.body_as_hash[:tasks].size).to eq 1
      end

      it "allows the end_at date to be specified alone" do
        api_get :dashboard, student_token, parameters: {
          id: course.id, end_at: time_zone.now - 2.weeks
        }

        expect(response.body_as_hash[:tasks]).to be_empty
      end
    end

    context 'teacher' do
      it 'returns an error if the course is a CC course' do
        course.update_attribute(:is_concept_coach, true)
        api_get :dashboard, teacher_token, parameters: {id: course.id}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'cc_course'
      end

      it "works without a role specified" do
        api_get :dashboard, teacher_token, parameters: {id: course.id}

        expect(HashWithIndifferentAccess[response.body_as_hash]).to include(
          "role" => {
            "id" => teacher_role.id.to_s,
            "type" => 'teacher'
          },
          "course" => {
            "name" => 'Physics 101',
            "teachers" => [
              { 'id' => teacher_role.teacher.id.to_s,
                'role_id' => teacher_role.id.to_s,
                'first_name' => 'Bob',
                'last_name' => 'Newhart' }
            ]
          },
          "tasks" => [],
          "plans" => a_collection_including(
            a_hash_including(
              "id" => plan.id.to_s,
              "type" => 'reading',
              "first_published_at" => be_kind_of(String),
              "last_published_at" => be_kind_of(String),
              "tasking_plans" => [
                a_hash_including(
                { "target_id" => course.id.to_s,
                  "target_type" => 'course',
                  "opens_at" => DateTimeUtilities.to_api_s(plan.tasking_plans.first.opens_at),
                  "due_at" => DateTimeUtilities.to_api_s(plan.tasking_plans.first.due_at)
                })
              ]
            )
          )
        )
      end

      it "works with a student role specified" do
        api_get :dashboard, teacher_token, parameters: { id: course.id, role_id: student_role }

        response_body = HashWithIndifferentAccess[response.body_as_hash]
        expect(response_body['role']).to eq({
          'id' => student_role.id.to_s,
          'type' => 'student'
        })
        expect(response_body['course']).to eq({
          'name' => 'Physics 101',
          'teachers' => [
            { 'id' => teacher_role.teacher.id.to_s,
              'role_id' => teacher_role.id.to_s,
              'first_name' => 'Bob',
              'last_name' => 'Newhart' }
          ]
        })
        expect(response_body['tasks']).not_to be_empty
        expect(response_body['plans']).to be_nil
      end

      it "allows the start_at and end_at dates to be specified" do
        api_get :dashboard, teacher_token, parameters: {
          id: course.id, start_at: time_zone.now - 2.hours, end_at: time_zone.now - 1.hour
        }

        expect(response.body_as_hash[:plans]).to be_empty
      end

      it "allows the start_at date to be specified alone" do
        api_get :dashboard, teacher_token, parameters: {
          id: course.id, start_at: time_zone.now - 2.hours
        }

        expect(response.body_as_hash[:plans].size).to eq 1
      end

      it "allows the end_at date to be specified alone" do
        api_get :dashboard, teacher_token, parameters: {
          id: course.id, end_at: time_zone.now - 1.hours
        }

        expect(response.body_as_hash[:plans]).to be_empty
      end
    end
  end

  context '#cc_dashboard' do
    let(:student_user)    { FactoryGirl.create(:user) }
    let!(:student_role)   { AddUserAsPeriodStudent[user: student_user, period: period] }
    let(:student_token)   { FactoryGirl.create :doorkeeper_access_token,
                                               resource_owner_id: student_user.id }

    let(:student_user_2)  { FactoryGirl.create(:user) }
    let!(:student_role_2) { AddUserAsPeriodStudent[user: student_user_2, period: period] }

    let(:teacher_user)    { FactoryGirl.create(:user, first_name: 'Bob',
                                                      last_name: 'Newhart',
                                                      full_name: 'Bob Newhart') }
    let!(:teacher_role)   { AddUserAsCourseTeacher[user: teacher_user, course: course] }
    let(:teacher_token)   { FactoryGirl.create :doorkeeper_access_token,
                                               resource_owner_id: teacher_user.id }

    before(:all)         do
      @book = FactoryGirl.create :content_book
      @chapter_1 = FactoryGirl.create :content_chapter, book: @book, book_location: [1]
      @chapter_2 = FactoryGirl.create :content_chapter, book: @book, book_location: [2]
      cnx_page_1 = OpenStax::Cnx::V1::Page.new(id: 'ad9b9d37-a5cf-4a0d-b8c1-083fcc4d3b0c',
                                               title: 'Sample module 1')
      cnx_page_2 = OpenStax::Cnx::V1::Page.new(id: '6a0568d8-23d7-439b-9a01-16e4e73886b3',
                                               title: 'The Science of Biology')
      cnx_page_3 = OpenStax::Cnx::V1::Page.new(id: '7636a3bf-eb80-4898-8b2c-e81c1711b99f',
                                               title: 'Sample module 2')
      book_location_1 = [1, 1]
      book_location_2 = [1, 2]
      book_location_3 = [2, 1]

      page_model_1, page_model_2, page_model_3 = \
        VCR.use_cassette('Api_V1_CoursesController/with_pages', VCR_OPTS) do
          OpenStax::Cnx::V1.with_archive_url('https://archive.cnx.org/') do
            [Content::Routines::ImportPage[chapter: @chapter_1,
                                           cnx_page: cnx_page_1,
                                           book_location: book_location_1],
             Content::Routines::ImportPage[chapter: @chapter_1,
                                           cnx_page: cnx_page_2,
                                           book_location: book_location_2],
             Content::Routines::ImportPage[chapter: @chapter_2,
                                           cnx_page: cnx_page_3,
                                           book_location: book_location_3]]
          end
        end

      Content::Routines::PopulateExercisePools[book: @book]

      @page_1 = Content::Page.new(strategy: page_model_1.reload.wrap)
      @page_2 = Content::Page.new(strategy: page_model_2.reload.wrap)
      @page_3 = Content::Page.new(strategy: page_model_3.reload.wrap)

      ecosystem_model = @book.ecosystem
      @ecosystem = Content::Ecosystem.new(strategy: ecosystem_model.wrap)
    end

    before(:each) do
      course.name = 'Biology 101'
      course.is_concept_coach = true
      course.save!

      AddEcosystemToCourse[ecosystem: @ecosystem, course: course]

      @task_1 = GetConceptCoach[
        user: student_user, cnx_book_id: @book.uuid, cnx_page_id: @page_1.uuid
      ]
      @task_1.task_steps.each do |ts|
        Demo::AnswerExercise[task_step: ts, is_correct: true]
      end
      @task_2 = GetConceptCoach[
        user: student_user, cnx_book_id: @book.uuid, cnx_page_id: @page_2.uuid
      ]
      @task_2.task_steps.each do |ts|
        Demo::AnswerExercise[task_step: ts, is_correct: false]
      end
      @task_3 = GetConceptCoach[
        user: student_user, cnx_book_id: @book.uuid, cnx_page_id: @page_3.uuid
      ]
      @task_3.task_steps.each do |ts|
        Demo::AnswerExercise[task_step: ts, is_correct: ts.core_group?]
      end
      @task_4 = GetConceptCoach[
        user: student_user_2, cnx_book_id: @book.uuid, cnx_page_id: @page_1.uuid
      ]
      @task_4.task_steps.select(&:core_group?).first(2).each_with_index do |ts, ii|
        Demo::AnswerExercise[task_step: ts, is_correct: ii == 0]
      end
      @task_5 = GetConceptCoach[
        user: student_user_2, cnx_book_id: @book.uuid, cnx_page_id: @page_2.uuid
      ]
    end

    context 'anonymous' do
      it 'raises SecurityTransgression if user is anonymous or not in course' do
        expect {
          api_get :cc_dashboard, nil, parameters: { id: course.id }
        }.to raise_error(SecurityTransgression)

        expect {
          api_get :cc_dashboard, user_1_token, parameters: { id: course.id }
        }.to raise_error(SecurityTransgression)
      end
    end

    context 'student' do
      it 'returns an error if the course is a non-CC course' do
        course.update_attribute(:is_concept_coach, false)
        api_get :cc_dashboard, student_token, parameters: {id: course.id}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'non_cc_course'
      end

      it "works without a role specified" do
        api_get :cc_dashboard, student_token, parameters: {id: course.id}

        expect(HashWithIndifferentAccess[response.body_as_hash]).to include(

          "tasks" => a_collection_including(
            a_hash_including(
              "id" => @task_1.id.to_s,
              "title" => @task_1.title,
              "last_worked_at" => be_kind_of(String),
              "type" => 'concept_coach',
              "complete" => true
            ),
            a_hash_including(
              "id" => @task_2.id.to_s,
              "title" => @task_2.title,
              "last_worked_at" => be_kind_of(String),
              "type" => 'concept_coach',
              "complete" => true
            ),
            a_hash_including(
              "id" => @task_3.id.to_s,
              "title" => @task_3.title,
              "last_worked_at" => be_kind_of(String),
              "type" => 'concept_coach',
              "complete" => true
            )
          ),
          "role" => {
            "id" => student_role.id.to_s,
            "type" => 'student'
          },
          "course" => {
            "name" => 'Biology 101',
            "teachers" => [
              { 'id' => teacher_role.teacher.id.to_s,
                'role_id' => teacher_role.id.to_s,
                'first_name' => 'Bob',
                'last_name' => 'Newhart' }
            ]
          },
          "chapters" => [
            {
              "id" => @chapter_2.id.to_s,
              "title" => @chapter_2.title,
              "chapter_section" => [2],
              "pages" => [
                {
                  "id" => @page_3.id.to_s,
                  "title" => @page_3.title,
                  "uuid" => @page_3.uuid,
                  "version" => @page_3.version,
                  "chapter_section" => [2, 1],
                  "last_worked_at" => be_kind_of(String),
                  "exercises" => Tasks::Models::ConceptCoachTask::CORE_EXERCISES_COUNT.times.map do
                    {
                      "id" => a_kind_of(String),
                      "is_completed" => true,
                      "is_correct" => true
                    }
                  end + Tasks::Models::ConceptCoachTask::SPACED_EXERCISES_MAP
                          .select{ |k_ago, ex_count| k_ago != :random && k_ago <= 2 }
                          .map{ |k_ago, ex_count| ex_count }.reduce(0, :+).times.map do
                    {
                      "id" => a_kind_of(String),
                      "is_completed" => true,
                      "is_correct" => false
                    }
                  end
                }
              ]
            },
            {
              "id" => @chapter_1.id.to_s,
              "title" => @chapter_1.title,
              "chapter_section" => [1],
              "pages" => [
                {
                  "id" => @page_2.id.to_s,
                  "title" => @page_2.title,
                  "uuid" => @page_2.uuid,
                  "version" => @page_2.version,
                  "chapter_section" => [1, 2],
                  "last_worked_at" => be_kind_of(String),
                  "exercises" => Tasks::Models::ConceptCoachTask::CORE_EXERCISES_COUNT.times.map do
                    {
                      "id" => a_kind_of(String),
                      "is_completed" => true,
                      "is_correct" => false
                    }
                  end
                },
                {
                  "id" => @page_1.id.to_s,
                  "title" => @page_1.title,
                  "uuid" => @page_1.uuid,
                  "version" => @page_1.version,
                  "chapter_section" => [1, 1],
                  "last_worked_at" => be_kind_of(String),
                  "exercises" => Tasks::Models::ConceptCoachTask::CORE_EXERCISES_COUNT.times.map do
                    {
                      "id" => a_kind_of(String),
                      "is_completed" => true,
                      "is_correct" => true
                    }
                  end
                }
              ]
            }
          ]
        )
      end
    end

    context 'teacher' do
      it 'returns an error if the course is a non-CC course' do
        course.update_attribute(:is_concept_coach, false)
        api_get :cc_dashboard, teacher_token, parameters: {id: course.id}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'non_cc_course'
      end

      it "works without a role specified" do
        api_get :cc_dashboard, teacher_token, parameters: {id: course.id}

        expect(HashWithIndifferentAccess[response.body_as_hash]).to include(
          "role" => {
            "id" => teacher_role.id.to_s,
            "type" => 'teacher'
          },
          "course" => {
            "name" => 'Biology 101',
            "teachers" => [
              { 'id' => teacher_role.teacher.id.to_s,
                'role_id' => teacher_role.id.to_s,
                'first_name' => 'Bob',
                'last_name' => 'Newhart' }
            ],
            "periods" => [
              {
                "id" => period.id.to_s,
                "name" => period.name,
                "chapters" => [
                  {
                    "id" => @chapter_2.id.to_s,
                    "title" => @chapter_2.title,
                    "chapter_section" => [2],
                    "pages" => [
                      {
                        "id" => @page_3.id.to_s,
                        "title" => @page_3.title,
                        "uuid" => @page_3.uuid,
                        "version" => @page_3.version,
                        "chapter_section" => [2, 1],
                        "completed" => 1,
                        "in_progress" => 0,
                        "not_started" => 1,
                        "original_performance" => 1.0
                      }
                    ]
                  },
                  {
                    "id" => @chapter_1.id.to_s,
                    "title" => @chapter_1.title,
                    "chapter_section" => [1],
                    "pages" => [
                      {
                        "id" => @page_2.id.to_s,
                        "title" => @page_2.title,
                        "uuid" => @page_2.uuid,
                        "version" => @page_2.version,
                        "chapter_section" => [1, 2],
                        "completed" => 1,
                        "in_progress" => 0,
                        "not_started" => 1,
                        "original_performance" => 0.0
                      },
                      {
                        "id" => @page_1.id.to_s,
                        "title" => @page_1.title,
                        "uuid" => @page_1.uuid,
                        "version" => @page_1.version,
                        "chapter_section" => [1, 1],
                        "completed" => 1,
                        "in_progress" => 1,
                        "not_started" => 0,
                        "original_performance" => 0.8,
                        "spaced_practice_performance" => 0.0
                      }
                    ]
                  }
                ]
              }
            ]
          },
          "tasks" => []
        )
      end

      it "works with a student role specified" do
        api_get :cc_dashboard, teacher_token, parameters: { id: course.id, role_id: student_role }

        response_body = HashWithIndifferentAccess[response.body_as_hash]
        expect(response_body['role']).to eq({
          'id' => student_role.id.to_s,
          'type' => 'student'
        })
        expect(response_body['course']).to eq({
          'name' => 'Biology 101',
          'teachers' => [
            { 'id' => teacher_role.teacher.id.to_s,
              'role_id' => teacher_role.id.to_s,
              'first_name' => 'Bob',
              'last_name' => 'Newhart' }
          ]
        })
        expect(response_body['chapters']).not_to be_empty
        expect(response_body['tasks']).not_to be_empty
      end
    end
  end

  context '#roster' do
    let(:application)        { FactoryGirl.create :doorkeeper_application }

    let(:course)             { FactoryGirl.create :course_profile_course }
    let!(:period_2)          { FactoryGirl.create :course_membership_period, course: course }

    let(:student_user)       { FactoryGirl.create(:user) }
    let(:student_role)       { AddUserAsPeriodStudent[user: student_user, period: period] }
    let!(:student)           { student_role.student }
    let(:student_token)      { FactoryGirl.create :doorkeeper_access_token,
                                                  application: application,
                                                  resource_owner_id: student_user.id }

    let(:student_user_2)     { FactoryGirl.create(:user) }
    let(:student_role_2)     { AddUserAsPeriodStudent[user: student_user_2, period: period] }
    let!(:student_2)         { student_role_2.student }

    let(:teacher_user)       { FactoryGirl.create(:user) }
    let!(:teacher_role)      { AddUserAsCourseTeacher[user: teacher_user, course: course] }
    let(:teacher_token)      { FactoryGirl.create :doorkeeper_access_token,
                                                  application: application,
                                                  resource_owner_id: teacher_user.id }

    let(:student_user_3)     { FactoryGirl.create(:user) }
    let(:student_role_3)     { AddUserAsPeriodStudent[user: student_user_3, period: period_2] }
    let!(:student_3)         { student_role_3.student }

    let(:valid_params) { { id: course.id } }

    context 'caller has an authorization token' do
      context 'caller is a course teacher' do
        it 'returns the course roster' do
          api_get :roster, teacher_token, parameters: valid_params
          expect(response).to have_http_status(:ok)
          roster = response.body_as_hash
          expect(roster).to include({
            teach_url: a_string_matching(/.*teach\/[a-f0-9]{32}\/DO_NOT.*/),
            teachers: a_collection_containing_exactly(
              {
                id: teacher_role.teacher.id.to_s,
                role_id: teacher_role.id.to_s,
                first_name: teacher_user.first_name,
                last_name: teacher_user.last_name,
              }
            ),
            students: a_collection_containing_exactly(
              {
                id: student.id.to_s,
                first_name: student.first_name,
                last_name: student.last_name,
                name: student.name,
                period_id: period.id.to_s,
                role_id: student_role.id.to_s,
                is_active: true
              },
              {
                id: student_2.id.to_s,
                first_name: student_2.first_name,
                last_name: student_2.last_name,
                name: student_2.name,
                period_id: period.id.to_s,
                role_id: student_role_2.id.to_s,
                is_active: true
              },
              {
                id: student_3.id.to_s,
                first_name: student_3.first_name,
                last_name: student_3.last_name,
                name: student_3.name,
                period_id: period_2.id.to_s,
                role_id: student_role_3.id.to_s,
                is_active: true
              }
            )
          })
        end
      end

      context 'caller is not a course teacher' do
        it 'raises SecurityTransgression' do
          expect{
            api_get :roster, student_token, parameters: valid_params
          }.to raise_error(SecurityTransgression)
        end
      end
    end

    context 'caller has an application/client credentials authorization token' do
      it 'raises SecurityTransgression' do
        expect{
          api_get :roster, userless_token, parameters: valid_params
        }.to raise_error(SecurityTransgression)
      end
    end

    context 'caller does not have an authorization token' do
      it 'raises SecurityTransgression' do
        expect{
          api_get :roster, nil, parameters: valid_params
        }.to raise_error(SecurityTransgression)
      end
    end
  end

  context '#clone' do
    let(:roles)          { Role::GetUserRoles.call(user_1).outputs.roles }
    let(:teacher)        { roles.select(&:teacher?).first }
    let(:student)        { roles.select(&:student?).first }
    let!(:zeroth_period) do
      FactoryGirl.create :course_membership_period, course: course, name: '0th'
    end

    let(:valid_params) { { id: course.id                } }
    let(:valid_body)   { { copy_question_library: false } }

    before { zeroth_period.to_model.destroy! }

    context 'anonymous user' do
      it 'raises SecurityTransgression' do
        expect{ api_post :clone, nil, parameters: valid_params }.to(
          raise_error(SecurityTransgression)
        )
      end
    end

    context 'user is not in the course' do
      it 'raises SecurityTransgression' do
        expect{ api_post :clone, user_1_token, parameters: valid_params }.to(
          raise_error(SecurityTransgression)
        )
      end
    end

    context 'user is a student in the course' do
      before do
        AddUserAsPeriodStudent.call(period: period, user: user_1)
      end

      it 'raises SecurityTransgression' do
        expect{ api_post :clone, user_1_token, parameters: valid_params }.to(
          raise_error(SecurityTransgression)
        )
      end
    end

    context 'user is a teacher in the course' do
      let(:expected_response) do
        {
          id: a_kind_of(String),
          term: course.term,
          year: course.year + 1,
          starts_at: a_kind_of(String),
          ends_at: a_kind_of(String),
          is_active: be_in([true, false]),
          is_college: course.is_college,
          is_concept_coach: course.is_concept_coach,
          num_sections: course.num_sections,
          offering_id: course.offering.id.to_s,
          appearance_code: course.offering.appearance_code,
          salesforce_book_name: course.offering.salesforce_book_name,
          webview_url: course.offering.webview_url,
          book_pdf_url: course.offering.pdf_url,
          time_zone: course.time_zone.name,
          default_due_time: course.default_due_time,
          default_open_time: course.default_open_time,
          name: course.name,
          cloned_from_id: course.id.to_s,
          periods: [a_kind_of(Hash)]*course.num_sections,
          students: [],
          roles: [a_kind_of(Hash)],
          ecosystem_id: course.offering.content_ecosystem_id.to_s
        }
      end

      before do
        AddUserAsCourseTeacher.call(course: course, user: user_1)
      end

      it 'clones the course for the user' do
        api_post :clone, user_1_token, parameters: valid_params, raw_post_data: valid_body

        expect(response).to have_http_status(:success)
        expect(response.body_as_hash).to match expected_response
      end
    end
  end

end
