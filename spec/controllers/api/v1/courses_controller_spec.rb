require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Api::V1::CoursesController, type: :controller, api: true,
                                           version: :v1, speed: :slow, vcr: VCR_OPTS do

  let!(:user_1)             { FactoryGirl.create(:user) }
  let!(:user_1_token)       { FactoryGirl.create :doorkeeper_access_token,
                                                 resource_owner_id: user_1.id }

  let!(:user_2)             { FactoryGirl.create(:user) }
  let!(:user_2_token)       { FactoryGirl.create :doorkeeper_access_token,
                                                 resource_owner_id: user_2.id }

  let!(:userless_token)     { FactoryGirl.create :doorkeeper_access_token }

  let!(:course)             { CreateCourse[name: 'Physics 101'] }
  let!(:period)             { CreatePeriod[course: course] }

  def add_book_to_course(course:)
    book = FactoryGirl.create(:content_book, :standard_contents_1)
    content_ecosystem = book.ecosystem.reload
    strategy = Content::Strategies::Direct::Ecosystem.new(content_ecosystem)
    ecosystem = Content::Ecosystem.new(strategy: strategy)
    CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: ecosystem)

    { book: book, ecosystem: ecosystem }
  end

  describe "tasks" do
    it "temporarily mirrors /api/user/tasks" do
      api_get :tasks, user_1_token, parameters: {id: course.id}
      expect(response.code).to eq('200')
      expect(response.body).to eq({
        total_count: 0,
        items: []
      }.to_json)
    end

    it "returns tasks for a role holder in a certain course" do
      skip "skipped until implement the real /api/courses/123/tasks endpoint with role awareness"
    end
  end

  describe "index" do
    let(:roles)          { Role::GetUserRoles.call(user_1).outputs.roles }
    let(:teacher)        { roles.select(&:teacher?).first }
    let(:student)        { roles.select(&:student?).first }
    let!(:zeroth_period) { CreatePeriod[course: course, name: '0th'] }

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

      it 'includes the periods and ecosystem_id for the course' do
        ecosystem = add_book_to_course(course: course)[:ecosystem]

        api_get :index, user_1_token
        expect(response.body).to include({
          id: course.id.to_s,
          name: course.profile.name,
          ecosystem_id: "#{ecosystem.id}",
          is_concept_coach: false,
          roles: [{ id: teacher.id.to_s, type: 'teacher' }],
          periods: [{ id: zeroth_period.id.to_s,
                      name: zeroth_period.name,
                      enrollment_code: zeroth_period.enrollment_code },
                    { id: period.id.to_s,
                      name: period.name,
                      enrollment_code: period.enrollment_code }]
        }.to_json)
      end
    end

    context 'user is a teacher' do
      before do
        AddUserAsCourseTeacher.call(course: course, user: user_1)
      end

      it 'returns the teacher roles with the course' do
        api_get :index, user_1_token
        expect(response.body_as_hash.first).to match a_hash_including(
          roles: a_collection_containing_exactly({ id: teacher.id.to_s, type: 'teacher' })
        )
      end
    end

    context 'user is a student' do
      before(:each) do
        AddUserAsPeriodStudent.call(period: period, user: user_1)
      end

      it 'returns the student roles with the course' do
        api_get :index, user_1_token
        expect(response.body_as_hash.first).to match a_hash_including(
          roles: a_collection_containing_exactly({ id: student.id.to_s, type: 'student' }),
        )
      end
    end

    context 'user is both a teacher and student' do
      before(:each) do
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

  describe "show" do
    let(:roles)          { Role::GetUserRoles.call(user_1).outputs.roles }
    let(:teacher)        { roles.select(&:teacher?).first }
    let(:student)        { roles.select(&:student?).first }
    let!(:zeroth_period) { CreatePeriod[course: course, name: '0th'] }

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

  describe "update" do
    context 'anonymous user' do
      it 'raises SecurityTransgression' do
        expect {
          api_patch :update, nil, parameters: { id: course.id,
                                                course: { name: 'Renamed' } }
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
          api_patch :update, user_1_token, parameters: { id: course.id,
                                                         course: { name: 'Renamed' } }
        }.to raise_error(SecurityTransgression)
        expect(course.reload.name).to eq 'Physics 101'
      end
    end

    context 'user is a teacher' do
      before do
        AddUserAsCourseTeacher.call(user: user_1, course: course)
      end

      it 'renames the course' do
        api_patch :update, user_1_token, parameters: { id: course.id,
                                                       course: { name: 'Renamed' } }
        expect(course.reload.name).to eq 'Renamed'
        expect(response.body_as_hash[:name]).to eq 'Renamed'
      end
    end
  end

  describe "dashboard" do
    let!(:student_user)   { FactoryGirl.create(:user) }
    let!(:student_role)   { AddUserAsPeriodStudent[user: student_user, period: period] }
    let!(:student_token)  { FactoryGirl.create :doorkeeper_access_token,
                                               resource_owner_id: student_user.id }

    let!(:teacher_user)   { FactoryGirl.create(:user, first_name: 'Bob',
                                                      last_name: 'Newhart',
                                                      full_name: 'Bob Newhart') }
    let!(:teacher_role)   { AddUserAsCourseTeacher[user: teacher_user, course: course] }
    let!(:teacher_token)  { FactoryGirl.create :doorkeeper_access_token,
                                               resource_owner_id: teacher_user.id }

    let!(:reading_task)   { FactoryGirl.create(:tasks_task,
                                               task_type: :reading,
                                               opens_at: Time.now - 1.week,
                                               due_at: Time.now,
                                               step_types: [:tasks_tasked_reading,
                                                            :tasks_tasked_exercise,
                                                            :tasks_tasked_exercise],
                                               tasked_to: student_role)}

    let!(:hw1_task)   { FactoryGirl.create(:tasks_task,
                                           task_type: :homework,
                                           opens_at: Time.now - 1.week,
                                           due_at: Time.now,
                                           step_types: [:tasks_tasked_exercise,
                                                        :tasks_tasked_exercise,
                                                        :tasks_tasked_exercise],
                                           tasked_to: student_role)}

    let!(:hw2_task)   { FactoryGirl.create(:tasks_task,
                                           task_type: :homework,
                                           opens_at: Time.now - 1.week,
                                           due_at: Time.now,
                                           step_types: [:tasks_tasked_exercise,
                                                        :tasks_tasked_exercise,
                                                        :tasks_tasked_exercise],
                                           tasked_to: student_role)}

    let!(:hw3_task)   { FactoryGirl.create(:tasks_task,
                                           task_type: :homework,
                                           opens_at: Time.now - 1.week,
                                           due_at: Time.now+2.weeks,
                                           step_types: [:tasks_tasked_exercise,
                                                        :tasks_tasked_exercise,
                                                        :tasks_tasked_exercise],
                                           tasked_to: student_role)}

    let!(:plan) { FactoryGirl.create(:tasks_task_plan, owner: course,
                                                       published_at: Time.now - 1.week)}

    it 'raises SecurityTransgression if user is anonymous or not in course' do
      expect {
        api_get :dashboard, nil, parameters: { id: course.id }
      }.to raise_error(SecurityTransgression)

      expect {
        api_get :dashboard, user_1_token, parameters: { id: course.id }
      }.to raise_error(SecurityTransgression)
    end

    it 'returns an error if the course is a CC course' do
      course.profile.update_attribute(:is_concept_coach, true)
      api_get :dashboard, student_token, parameters: {id: course.id}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body_as_hash[:errors].first[:code]).to eq 'cc_course'
    end

    it "works for a student without a role specified" do
      Hacks::AnswerExercise[task_step: hw1_task.task_steps[0], is_correct: true]
      Hacks::AnswerExercise[task_step: hw1_task.task_steps[2], is_correct: false]

      Hacks::AnswerExercise[task_step: hw2_task.task_steps[0], is_correct: true]
      Hacks::AnswerExercise[task_step: hw2_task.task_steps[1], is_correct: true]
      Hacks::AnswerExercise[task_step: hw2_task.task_steps[2], is_correct: false]

      Hacks::AnswerExercise[task_step: hw3_task.task_steps[0], is_correct: false]
      Hacks::AnswerExercise[task_step: hw3_task.task_steps[1], is_correct: false]
      Hacks::AnswerExercise[task_step: hw3_task.task_steps[2], is_correct: false]


      api_get :dashboard, student_token, parameters: {id: course.id}

      expect(HashWithIndifferentAccess[response.body_as_hash]).to include(

        "tasks" => a_collection_including(
          a_hash_including(
            "id" => reading_task.id.to_s,
            "title" => reading_task.title,
            "due_at" => be_kind_of(String),
            "type" => "reading",
            "complete" => false,
            "exercise_count" => 2,
            "complete_exercise_count" => 0
          ),
          a_hash_including(
            "id" => hw1_task.id.to_s,
            "title" => hw1_task.title,
            "opens_at" => be_kind_of(String),
            "due_at" => be_kind_of(String),
            "type" => "homework",
            "complete" => false,
            "exercise_count" => 3,
            "complete_exercise_count" => 2
          ),
          a_hash_including(
            "id" => hw2_task.id.to_s,
            "title" => hw2_task.title,
            "opens_at" => be_kind_of(String),
            "due_at" => be_kind_of(String),
            "type" => "homework",
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
            "type" => "homework",
            "complete" => true,
            "exercise_count" => 3,
            "complete_exercise_count" => 3,
          ),
        ),
        "role" => {
          "id" => student_role.id.to_s,
          "type" => "student"
        },
        "course" => {
          "name" => "Physics 101",
          "teachers" => [
            { 'id' => teacher_role.teacher.id.to_s,
              'role_id' => teacher_role.id.to_s,
              'first_name' => 'Bob',
              'last_name' => 'Newhart' }
          ]
        }
      )
    end

    it "works for a teacher without a role specified" do
      api_get :dashboard, teacher_token, parameters: {id: course.id}

      expect(HashWithIndifferentAccess[response.body_as_hash]).to include(
        "role" => {
          "id" => teacher_role.id.to_s,
          "type" => "teacher"
        },
        "course" => {
          "name" => "Physics 101",
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
            "type" => "reading",
            "published_at" => be_kind_of(String),
            "tasking_plans" => [
              { "target_id" => course.id.to_s,
                "target_type" => 'course',
                "opens_at" => DateTimeUtilities.to_api_s(plan.tasking_plans.first.opens_at),
                "due_at" => DateTimeUtilities.to_api_s(plan.tasking_plans.first.due_at)
              }
            ]
          )
        )
      )
    end

    it "works for a teacher with student role specified" do
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
  end

  describe "cc_dashboard" do
    let!(:student_user)   { FactoryGirl.create(:user) }
    let!(:student_role)   { AddUserAsPeriodStudent[user: student_user, period: period] }
    let!(:student_token)  { FactoryGirl.create :doorkeeper_access_token,
                                               resource_owner_id: student_user.id }

    let!(:student_user_2) { FactoryGirl.create(:user) }
    let!(:student_role_2) { AddUserAsPeriodStudent[user: student_user_2, period: period] }

    let!(:teacher_user)   { FactoryGirl.create(:user, first_name: 'Bob',
                                                    last_name: 'Newhart',
                                                    full_name: 'Bob Newhart') }
    let!(:teacher_role)   { AddUserAsCourseTeacher[user: teacher_user, course: course] }
    let!(:teacher_token)  { FactoryGirl.create :doorkeeper_access_token,
                                               resource_owner_id: teacher_user.id }

    before(:all)         do
      DatabaseCleaner.start

      @chapter = FactoryGirl.create :content_chapter, book_location: [4]
      cnx_page_1 = OpenStax::Cnx::V1::Page.new(id: '95e61258-2faf-41d4-af92-f62e1414175a',
                                               title: 'Force')
      cnx_page_2 = OpenStax::Cnx::V1::Page.new(id: '640e3e84-09a5-4033-b2a7-b7fe5ec29dc6',
                                               title: "Newton's First Law of Motion: Inertia")
      book_location_1 = [4, 1]
      book_location_2 = [4, 2]

      page_model_1, page_model_2 = VCR.use_cassette('Api_V1_CoursesController/with_pages',
                                                    VCR_OPTS) do
        [Content::Routines::ImportPage[chapter: @chapter,
                                       cnx_page: cnx_page_1,
                                       book_location: book_location_1],
         Content::Routines::ImportPage[chapter: @chapter,
                                       cnx_page: cnx_page_2,
                                       book_location: book_location_2]]
      end

      @book = @chapter.book
      Content::Routines::PopulateExercisePools[book: @book]

      @page_1 = Content::Page.new(strategy: page_model_1.reload.wrap)
      @page_2 = Content::Page.new(strategy: page_model_2.reload.wrap)

      ecosystem_model = @book.ecosystem
      @ecosystem = Content::Ecosystem.new(strategy: ecosystem_model.wrap)
    end

    before(:each) do
      course.profile.update_attribute(:is_concept_coach, true)

      AddEcosystemToCourse[ecosystem: @ecosystem, course: course]

      @task_1 = GetConceptCoach[
        user: student_user, cnx_book_id: @book.uuid, cnx_page_id: @page_1.uuid
      ].task
      @task_1.task_steps.each do |ts|
        Hacks::AnswerExercise[task_step: ts, is_correct: true]
      end
      @task_2 = GetConceptCoach[
        user: student_user, cnx_book_id: @book.uuid, cnx_page_id: @page_2.uuid
      ].task
      @task_2.task_steps.each do |ts|
        Hacks::AnswerExercise[task_step: ts, is_correct: ts.core_group?]
      end
      @task_3 = GetConceptCoach[
        user: student_user_2, cnx_book_id: @book.uuid, cnx_page_id: @page_1.uuid
      ].task
      @task_3.task_steps.select(&:core_group?).first(2).each_with_index do |ts, ii|
        Hacks::AnswerExercise[task_step: ts, is_correct: ii == 0]
      end
      @task_4 = GetConceptCoach[
        user: student_user_2, cnx_book_id: @book.uuid, cnx_page_id: @page_2.uuid
      ].task
    end

    after(:all) do
      DatabaseCleaner.clean
    end

    it 'raises SecurityTransgression if user is anonymous or not in course' do
      expect {
        api_get :cc_dashboard, nil, parameters: { id: course.id }
      }.to raise_error(SecurityTransgression)

      expect {
        api_get :cc_dashboard, user_1_token, parameters: { id: course.id }
      }.to raise_error(SecurityTransgression)
    end

    it 'returns an error if the course is a non-CC course' do
      course.profile.update_attribute(:is_concept_coach, false)
      api_get :cc_dashboard, student_token, parameters: {id: course.id}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body_as_hash[:errors].first[:code]).to eq 'non_cc_course'
    end

    it "works for a student without a role specified" do
      api_get :cc_dashboard, student_token, parameters: {id: course.id}

      expect(HashWithIndifferentAccess[response.body_as_hash]).to include(

        "tasks" => a_collection_including(
          a_hash_including(
            "id" => @task_1.id.to_s,
            "title" => @task_1.title,
            "opens_at" => be_kind_of(String),
            "last_worked_at" => be_kind_of(String),
            "type" => "concept_coach",
            "complete" => true
          ),
          a_hash_including(
            "id" => @task_2.id.to_s,
            "title" => @task_2.title,
            "opens_at" => be_kind_of(String),
            "last_worked_at" => be_kind_of(String),
            "type" => "concept_coach",
            "complete" => true
          )
        ),
        "role" => {
          "id" => student_role.id.to_s,
          "type" => "student"
        },
        "course" => {
          "name" => "Physics 101",
          "teachers" => [
            { 'id' => teacher_role.teacher.id.to_s,
              'role_id' => teacher_role.id.to_s,
              'first_name' => 'Bob',
              'last_name' => 'Newhart' }
          ]
        },
        "chapters" => [
          {
            "id" => @chapter.id.to_s,
            "title" => @chapter.title,
            "chapter_section" => [4],
            "pages" => [
              {
                "id" => @page_2.id.to_s,
                "title" => @page_2.title,
                "uuid" => @page_2.uuid,
                "version" => @page_2.version,
                "chapter_section" => [4, 2],
                "last_worked_at" => be_kind_of(String),
                "exercises" => Tasks::Models::ConceptCoachTask::CORE_EXERCISES_COUNT.times.map do
                  {
                    "id" => a_kind_of(String),
                    "is_completed" => true,
                    "is_correct" => true
                  }
                end + Tasks::Models::ConceptCoachTask::SPACED_EXERCISES_COUNT.times.map do
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
                "chapter_section" => [4, 1],
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

    it "works for a teacher without a role specified" do
      api_get :cc_dashboard, teacher_token, parameters: {id: course.id}

      expect(HashWithIndifferentAccess[response.body_as_hash]).to include(
        "role" => {
          "id" => teacher_role.id.to_s,
          "type" => "teacher"
        },
        "course" => {
          "name" => "Physics 101",
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
                  "id" => @chapter.id.to_s,
                  "title" => @chapter.title,
                  "chapter_section" => [4],
                  "pages" => [
                    {
                      "id" => @page_2.id.to_s,
                      "title" => @page_2.title,
                      "uuid" => @page_2.uuid,
                      "version" => @page_2.version,
                      "chapter_section" => [4, 2],
                      "completed" => 1,
                      "in_progress" => 0,
                      "not_started" => 1,
                      "original_performance" => 1.0
                    },
                    {
                      "id" => @page_1.id.to_s,
                      "title" => @page_1.title,
                      "uuid" => @page_1.uuid,
                      "version" => @page_1.version,
                      "chapter_section" => [4, 1],
                      "completed" => 1,
                      "in_progress" => 1,
                      "not_started" => 0,
                      "original_performance" => 5/6.to_f,
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

    it "works for a teacher with student role specified" do
      api_get :cc_dashboard, teacher_token, parameters: { id: course.id, role_id: student_role }

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
      expect(response_body['chapters']).not_to be_empty
      expect(response_body['tasks']).not_to be_empty
    end
  end

end
