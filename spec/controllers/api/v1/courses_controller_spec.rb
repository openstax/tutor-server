require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Api::V1::CoursesController, type: :controller, api: true,
                                           version: :v1, speed: :slow, vcr: VCR_OPTS do

  let!(:user_1)          { FactoryGirl.create :user_profile }
  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              resource_owner_id: user_1.id }

  let!(:user_2)          { FactoryGirl.create :user_profile }
  let!(:user_2_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              resource_owner_id: user_2.id }

  let!(:userless_token)  { FactoryGirl.create :doorkeeper_access_token }

  let!(:course)          { CreateCourse[name: 'Physics 101'] }
  let!(:period)          { CreatePeriod[course: course] }

  describe "#readings" do
    it 'raises SecurityTransgression if user is anonymous or not in the course' do
      root_book_part = FactoryGirl.create(:content_book_part)
      CourseContent::AddBookToCourse.call(course: course, book: root_book_part.book)

      expect {
        api_get :readings, nil, parameters: { id: course.id }
      }.to raise_error(SecurityTransgression)

      expect {
        api_get :readings, user_1_token, parameters: { id: course.id }
      }.to raise_error(SecurityTransgression)
    end

    it 'works for students in the course' do
      # used in FE for reference view
      root_book_part = FactoryGirl.create(:content_book_part, :standard_contents_1)
      CourseContent::AddBookToCourse.call(course: course, book: root_book_part.book)
      AddUserAsCourseTeacher.call(course: course, user: user_1.entity_user)
      AddUserAsPeriodStudent.call(period: period, user: user_2.entity_user)

      api_get :readings, user_1_token, parameters: { id: course.id }
      expect(response).to have_http_status(:success)
      teacher_response = response.body_as_hash

      api_get :readings, user_2_token, parameters: { id: course.id }
      expect(response).to have_http_status(:success)
      student_response = response.body_as_hash

      expect(teacher_response).to eq(student_response)
    end

    it "should work on the happy path" do
      root_book_part = FactoryGirl.create(:content_book_part, :standard_contents_1)
      CourseContent::AddBookToCourse.call(course: course, book: root_book_part.book)
      toc = Content::VisitBook[book: root_book_part.book, visitor_names: :toc]
      AddUserAsCourseTeacher.call(course: course, user: user_1.entity_user)

      api_get :readings, user_1_token, parameters: {id: course.id}
      expect(response).to have_http_status(:success)
      expect(response.body_as_hash).to eq([{
        id: toc.id.to_s,
        title: 'book title',
        type: 'part',
        chapter_section: [],
        children: [
          id: toc.children[0].id.to_s,
          title: 'unit 1',
          type: 'part',
          chapter_section: [1],
          children: [
            {
              id: toc.children[0].children[0].id.to_s,
              title: 'chapter 1',
              type: 'part',
              chapter_section: [1, 1],
              children: [
                {
                  id: toc.children[0].children[0].children[0].id.to_s,
                  cnx_id: Content::Models::Page.find(toc.children[0].children[0].children[0].id).cnx_id,
                  title: 'first page',
                  chapter_section: [1, 1, 1],
                  type: 'page'
                },
                {
                  id: toc.children[0].children[0].children[1].id.to_s,
                  cnx_id: Content::Models::Page.find(toc.children[0].children[0].children[1].id).cnx_id,
                  title: 'second page',
                  chapter_section: [1, 1, 2],
                  type: 'page'
                }
              ]
            },
            {
              id: toc.children[0].children[1].id.to_s,
              title: 'chapter 2',
              type: 'part',
              chapter_section: [1, 2],
              children: [
                {
                  id: toc.children[0].children[1].children[0].id.to_s,
                  cnx_id: Content::Models::Page.find(toc.children[0].children[1].children[0].id).cnx_id,
                  title: 'third page',
                  chapter_section: [1, 2, 1],
                  type: 'page'
                }
              ]
            }
          ]
        ]
      }])

    end
  end

  describe "#plans" do
    let!(:task_plan) { FactoryGirl.create :tasks_task_plan, owner: course }

    it 'raises SecurityTransgression if user is anonymous or not in the course' do
      expect {
        api_get :plans, nil, parameters: { id: course.id }
      }.to raise_error(SecurityTransgression)

      expect {
        api_get :plans, user_1_token, parameters: { id: course.id }
      }.to raise_error(SecurityTransgression)
    end

    it 'returns task plans for course teachers' do
      AddUserAsCourseTeacher.call(course: course, user: user_1.entity_user)
      api_get :plans, user_1_token, parameters: {id: course.id}

      expect(response).to have_http_status(:success)
      expect(response.body).to(
        eq({ total_count: 1, items: [Api::V1::TaskPlanRepresenter.new(task_plan)] }.to_json)
      )
    end

    it 'returns task plans for course students' do
      AddUserAsPeriodStudent.call(period: period, user: user_2.entity_user)
      api_get :plans, user_2_token, parameters: {id: course.id}

      expect(response).to have_http_status(:success)
      expect(response.body).to(
        eq({ total_count: 1, items: [Api::V1::TaskPlanRepresenter.new(task_plan)] }.to_json)
      )
    end
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
    let(:roles)          { Role::GetUserRoles.call(user_1.entity_user).outputs.roles }
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
        AddUserAsCourseTeacher.call(course: course, user: user_1.entity_user)
      end

      it 'includes the periods for the course' do
        api_get :index, user_1_token
        expect(response.body).to include({
          id: course.id.to_s,
          name: course.profile.name,
          roles: [{ id: teacher.id.to_s, type: 'teacher' }],
          periods: [{ id: zeroth_period.id.to_s, name: zeroth_period.name },
                    { id: period.id.to_s, name: period.name }]
        }.to_json)
      end
    end

    context 'user is a teacher' do
      before do
        AddUserAsCourseTeacher.call(course: course, user: user_1.entity_user)
      end

      it 'returns the teacher roles with the course' do
        api_get :index, user_1_token
        expect(response.body).to include({
          id: course.id.to_s,
          name: course.profile.name,
          roles: [{ id: teacher.id.to_s, type: 'teacher' }],
          periods: [{ id: zeroth_period.id.to_s, name: zeroth_period.name },
                    { id: period.id.to_s, name: period.name }]
        }.to_json)
      end
    end

    context 'user is a student' do
      before(:each) do
        AddUserAsPeriodStudent.call(period: period, user: user_1.entity_user)
      end

      it 'returns the student roles with the course' do
        api_get :index, user_1_token
        expect(response.body).to include({
          id: course.id.to_s,
          name: course.profile.name,
          roles: [{ id: student.id.to_s, type: 'student' }],
          periods: [{ id: zeroth_period.id.to_s, name: zeroth_period.name },
                    { id: period.id.to_s, name: period.name }]
        }.to_json)
      end
    end

    context 'user is both a teacher and student' do
      before(:each) do
        AddUserAsPeriodStudent.call(period: period, user: user_1.entity_user)
        AddUserAsCourseTeacher.call(course: course, user: user_1.entity_user)
      end

      it 'returns both roles with the course' do
        api_get :index, user_1_token
        expect(response.body).to include({
          id: course.id.to_s,
          name: course.profile.name,
          roles: [{ id: student.id.to_s, type: 'student', },
                  { id: teacher.id.to_s, type: 'teacher', }],
          periods: [{ id: zeroth_period.id.to_s, name: zeroth_period.name },
                    { id: period.id.to_s, name: period.name }]
        }.to_json)
      end
    end
  end

  describe "show" do
    let(:roles)          { Role::GetUserRoles.call(user_1.entity_user).outputs.roles }
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
      let!(:teacher) { AddUserAsCourseTeacher.call(course: course, user: user_1.entity_user).outputs.role }

      it 'returns the teacher roles with the course' do
        api_get :show, user_1_token, parameters: { id: course.id }
        expect(response.body_as_hash).to match a_hash_including(
          id: course.id.to_s,
          name: course.profile.name,
          periods: [{ id: zeroth_period.id.to_s, name: zeroth_period.name },
                    { id: period.id.to_s, name: period.name }],
          roles: [{ id: teacher.id.to_s, type: 'teacher' }],
        )
      end
    end

    context 'user is a student' do
      let!(:student) { AddUserAsPeriodStudent.call(period: period, user: user_1.entity_user).outputs.role }

      it 'returns the student roles with the course' do
        api_get :show, user_1_token, parameters: { id: course.id }
        expect(response.body_as_hash).to match a_hash_including(
          id: course.id.to_s,
          name: course.profile.name,
          periods: [{ id: zeroth_period.id.to_s, name: zeroth_period.name },
                    { id: period.id.to_s, name: period.name }],
          roles: [{ id: student.id.to_s, type: 'student' }],
        )
      end
    end

    context 'user is both a teacher and student' do
      let!(:student) { AddUserAsPeriodStudent.call(period: period, user: user_1.entity_user).outputs.role }
      let!(:teacher) { AddUserAsCourseTeacher.call(course: course, user: user_1.entity_user).outputs.role }

      it 'returns both roles with the course' do
        api_get :show, user_1_token, parameters: { id: course.id }
        expect(response.body_as_hash).to match a_hash_including(
          id: course.id.to_s,
          name: course.profile.name,
          periods: [{ id: zeroth_period.id.to_s, name: zeroth_period.name },
                    { id: period.id.to_s, name: period.name }],
          roles: [{ id: student.id.to_s, type: 'student' },
                  { id: teacher.id.to_s, type: 'teacher' }],
        )
      end
    end
  end

  describe "practice_post" do
    let!(:lo)            { FactoryGirl.create :content_tag,
                                               tag_type: :lo,
                                               value: 'lo01' }

    let!(:page)           { FactoryGirl.create :content_page }

    let!(:page_tag)       { FactoryGirl.create :content_page_tag,
                                               page: page, tag: lo }

    let!(:exercise_1)     { FactoryGirl.create :content_exercise }
    let!(:exercise_2)     { FactoryGirl.create :content_exercise }
    let!(:exercise_3)     { FactoryGirl.create :content_exercise }
    let!(:exercise_4)     { FactoryGirl.create :content_exercise }
    let!(:exercise_5)     { FactoryGirl.create :content_exercise }

    let!(:exercise_tag_1) { FactoryGirl.create :content_exercise_tag,
                                               exercise: exercise_1, tag: lo }
    let!(:exercise_tag_2) { FactoryGirl.create :content_exercise_tag,
                                               exercise: exercise_2, tag: lo }
    let!(:exercise_tag_3) { FactoryGirl.create :content_exercise_tag,
                                               exercise: exercise_3, tag: lo }
    let!(:exercise_tag_4) { FactoryGirl.create :content_exercise_tag,
                                               exercise: exercise_4, tag: lo }
    let!(:exercise_tag_5) { FactoryGirl.create :content_exercise_tag,
                                               exercise: exercise_5, tag: lo }

    xit "works" do
      role = AddUserAsPeriodStudent.call(period: period, user: user_1.entity_user).outputs.role

      expect {
        api_post :practice,
                 user_1_token,
                 parameters: {id: course.id, role_id: role.id},
                 raw_post_data: { page_ids: [page.id.to_s] }.to_json
      }.to change{ Tasks::Models::Task.count }.by(1)

      expect(response).to have_http_status(:success)

      hash = response.body_as_hash
      expect(hash).to include(id: be_kind_of(String),
                              title: "Practice",
                              opens_at: be_kind_of(String),
                              steps: have(5).items)

      step_urls = Set.new hash[:steps].collect{|s| s[:content_url]}
      exercises = [exercise_1, exercise_2, exercise_3, exercise_4, exercise_5]
      exercise_urls = Set.new exercises.collect{ |e| e.url }
      expect(step_urls).to eq exercise_urls
    end

    xit "prefers unassigned exercises" do
      role = AddUserAsPeriodStudent.call(period: period, user: user_1.entity_user).outputs.role

      # Assign the first 5 exercises
      ResetPracticeWidget.call(role: role, condition: :local, page_ids: [page.id])

      # Then add 3 more to be assigned
      exercise_6 = FactoryGirl.create :content_exercise
      exercise_7 = FactoryGirl.create :content_exercise
      exercise_8 = FactoryGirl.create :content_exercise

      exercise_tag_6 = FactoryGirl.create :content_exercise_tag,
                                          exercise: exercise_6, tag: lo
      exercise_tag_7 = FactoryGirl.create :content_exercise_tag,
                                          exercise: exercise_7, tag: lo
      exercise_tag_8 = FactoryGirl.create :content_exercise_tag,
                                          exercise: exercise_8, tag: lo

      expect {
        api_post :practice,
                 user_1_token,
                 parameters: {id: course.id, role_id: role.id},
                 raw_post_data: { page_ids: [page.id.to_s] }.to_json
      }.to change{ Tasks::Models::Task.count }.by(1)

      expect(response).to have_http_status(:success)

      hash = response.body_as_hash
      expect(hash).to include(id: be_kind_of(String),
                              title: "Practice",
                              opens_at: be_kind_of(String),
                              steps: have(5).items)

      step_urls = Set.new hash[:steps].collect{|s| s[:content_url]}
      expect(step_urls).to include(exercise_6.url)
      expect(step_urls).to include(exercise_7.url)
      expect(step_urls).to include(exercise_8.url)

      exercises = [exercise_1, exercise_2, exercise_3, exercise_4,
                   exercise_5, exercise_6, exercise_7, exercise_8]
      exercise_urls = Set.new exercises.collect{ |e| e.url }
      expect(step_urls.proper_subset?(exercise_urls)).to eq true
    end

    it "must be called by a user who belongs to the course" do
      expect{
        api_post :practice, user_1_token, parameters: {id: course.id}
      }.to raise_error(IllegalState)
    end

    it "must be called by a user who has the role" do
      AddUserAsPeriodStudent.call(period: period, user: user_1.entity_user)
      expect{
        # The role belongs to user_1, we pass user_2_token
        api_post :practice, user_2_token, parameters: {id: course.id,
                                                       role_id: Entity::Role.last.id}
      }.to raise_error(IllegalState)
    end

  end

  describe "practice_get" do
    it "returns nothing when practice widget not yet set" do
      AddUserAsPeriodStudent.call(period: period, user: user_1.entity_user)
      api_get :practice, user_1_token, parameters: {id: course.id, role_id: Entity::Role.last.id}

      expect(response).to have_http_status(:not_found)
    end

    it "returns a practice widget" do
      AddUserAsPeriodStudent.call(period: period, user: user_1.entity_user)
      ResetPracticeWidget.call(role: Entity::Role.last, exercise_source: :fake)
      ResetPracticeWidget.call(role: Entity::Role.last, exercise_source: :fake)

      api_get :practice, user_1_token, parameters: {id: course.id, role_id: Entity::Role.last.id}

      expect(response).to have_http_status(:success)

      expect(response.body_as_hash).to include(id: be_kind_of(String),
                                               title: "Practice",
                                               opens_at: be_kind_of(String),
                                               steps: have(5).items)
    end

    it "can be called by a teacher using a student role" do
      AddUserAsCourseTeacher.call(course: course, user: user_1.entity_user)
      student_role = AddUserAsPeriodStudent.call(period: period, user: user_2.entity_user).outputs[:role]
      ResetPracticeWidget.call(role: student_role, exercise_source: :fake)

      api_get :practice, user_1_token, parameters: { id: course.id, role_id: student_role.id }

      expect(response).to have_http_status(:success)
    end

    it 'raises IllegalState if user is anonymous or not in the course or is not a student' do
      expect {
        api_get :practice, nil, parameters: { id: course.id }
      }.to raise_error(IllegalState)

      expect {
        api_get :practice, user_1_token, parameters: { id: course.id }
      }.to raise_error(IllegalState)

      AddUserAsCourseTeacher.call(course: course, user: user_1.entity_user)
      expect {
        api_get :practice, user_1_token, parameters: { id: course.id }
      }.to raise_error(IllegalState)
    end
  end

  describe "dashboard" do
    let!(:student_profile){ FactoryGirl.create(:user_profile) }
    let!(:student_user)   { student_profile.entity_user }
    let!(:student_role)   { AddUserAsPeriodStudent.call(user: student_user,
                                                        period: period)
                                                  .outputs.role }
    let!(:student_token)  { FactoryGirl.create :doorkeeper_access_token,
                                               resource_owner_id: student_profile.id }

    let!(:teacher_profile){ FactoryGirl.create(:user_profile,
                                               first_name: 'Bob',
                                               last_name: 'Newhart',
                                               full_name: 'Bob Newhart') }
    let!(:teacher_user)   { teacher_profile.entity_user }
    let!(:teacher_role)   { AddUserAsCourseTeacher.call(user: teacher_user,
                                                        course: course)
                                                  .outputs.role }
    let!(:teacher_token)  { FactoryGirl.create :doorkeeper_access_token,
                                               resource_owner_id: teacher_profile.id }

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

    it 'raises IllegalState if user is anonymous or not in course' do
      expect {
        api_get :dashboard, nil, parameters: { id: course.id }
      }.to raise_error(IllegalState)

      expect {
        api_get :dashboard, user_1_token, parameters: { id: course.id }
      }.to raise_error(IllegalState)
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
          "teacher_names" => [ "Bob Newhart" ]
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
          "teacher_names" => [ "Bob Newhart" ]
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
        'teacher_names' => ['Bob Newhart']
      })
      expect(response_body['tasks']).not_to be_empty
      expect(response_body['plans']).to be_nil
    end
  end

  context 'with book' do
    before(:all) do
      DatabaseCleaner.start

      VCR.use_cassette("Api_V1_CoursesController/with_book", VCR_OPTS) do
        @book = FetchAndImportBook[id: '93e2b09d-261c-4007-a987-0b3062fe154b']
      end
    end

    before(:each) do
      CourseContent::AddBookToCourse.call(course: course, book: @book)
    end

    after(:all) do
      DatabaseCleaner.clean
    end

    describe "#exercises" do
      before(:each) do
        AddUserAsCourseTeacher.call(course: course, user: user_1.entity_user)
      end

      it 'raises SecurityTransgression if user is anonymous or not a teacher' do
        page_ids = Content::Models::Page.all.map(&:id)

        expect {
          api_get :exercises, nil, parameters: { id: course.id, page_ids: page_ids }
        }.to raise_error(SecurityTransgression)

        expect {
          api_get :exercises, user_2_token, parameters: { id: course.id, page_ids: page_ids }
        }.to raise_error(SecurityTransgression)
      end

      it "should return an empty result if no page_ids specified" do
        api_get :exercises, user_1_token, parameters: {id: course.id}

        expect(response).to have_http_status(:success)
        expect(response.body_as_hash).to eq({total_count: 0, items: []})
      end

      it "should work on the happy path" do
        page_ids = Content::Models::Page.all.map(&:id)
        api_get :exercises, user_1_token, parameters: {id: course.id, page_ids: page_ids}

        expect(response).to have_http_status(:success)
        hash = response.body_as_hash
        expect(hash[:total_count]).to eq(70)
        page_los = Content::GetLos[page_ids: page_ids]
        hash[:items].each do |item|
          wrapper = OpenStax::Exercises::V1::Exercise.new(content: item[:content].to_json)
          item_los = wrapper.los
          expect(item_los).not_to be_empty
          item_los.each do |item_lo|
            expect(page_los).to include(item_lo)
          end
        end
      end
    end

    describe '#performance' do
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
        SetupPerformanceReportData[course: course,
                                   teacher: teacher,
                                   students: [student_1, student_2, student_3, student_4],
                                   book: @book]
      end

      it 'should work on the happy path' do
        api_get :performance, teacher_token, parameters: { id: course.id }

        expect(response).to have_http_status :success
        resp = response.body_as_hash
        expect(resp).to eq([{
          period_id: course.periods.first.id.to_s,
          data_headings: [
            { title: 'Homework task plan',
              plan_id: resp[0][:data_headings][0][:plan_id],
              due_at: resp[0][:data_headings][0][:due_at],
              average: 75.0 },

            { title: 'Reading task plan',
              plan_id: resp[0][:data_headings][1][:plan_id],
              due_at: resp[0][:data_headings][1][:due_at] },

            { title: 'Homework 2 task plan',
              plan_id: resp[0][:data_headings][2][:plan_id],
              due_at: resp[0][:data_headings][2][:due_at],
              average: 87.5 }
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
                exercise_count: 6,
                correct_exercise_count: 6,
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
                exercise_count: 4,
                correct_exercise_count: 3,
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
                exercise_count: 5,
                correct_exercise_count: 2,
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
                exercise_count: 3,
                correct_exercise_count: 1,
                recovered_exercise_count: 0,
                due_at: resp[0][:students][1][:data][2][:due_at],
                last_worked_at: resp[0][:students][1][:data][2][:last_worked_at]
              }
            ]
          }]
        }, {
          period_id: course.periods.order(:id).last.id.to_s,
          data_headings: [
            { title: 'Homework task plan',
              plan_id: resp[1][:data_headings][0][:plan_id],
              due_at: resp[1][:data_headings][0][:due_at],
              average: 100.0 },

            { title: 'Reading task plan',
              plan_id: resp[1][:data_headings][1][:plan_id],
              due_at: resp[1][:data_headings][1][:due_at]

            },

            { title: 'Homework 2 task plan',
              plan_id: resp[1][:data_headings][2][:plan_id],
              due_at: resp[1][:data_headings][2][:due_at] }
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
                exercise_count: 5,
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
                exercise_count: 3,
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
                status: 'completed',
                exercise_count: 6,
                correct_exercise_count: 6,
                recovered_exercise_count: 0,
                due_at: resp[1][:students][1][:data][0][:due_at],
                last_worked_at: resp[1][:students][1][:data][0][:last_worked_at]
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
                status: 'not_started',
                exercise_count: 3,
                correct_exercise_count: 0,
                recovered_exercise_count: 0,
                due_at: resp[1][:students][1][:data][2][:due_at]
              }
            ]
          }]
        }])
      end

      it 'raises error for users not in the course' do
        expect {
          api_get :performance, userless_token, parameters: { id: course.id }
        }.to raise_error StandardError
      end

      it 'raises error for students' do
        expect {
          api_get :performance, student_1_token, parameters: { id: course.id }
        }.to raise_error SecurityTransgression
      end
    end
  end

  describe 'POST #performance_export' do
    let(:teacher) { FactoryGirl.create :user_profile }
    let(:teacher_token) { FactoryGirl.create :doorkeeper_access_token,
                           resource_owner_id: teacher.id }

    before do
      AddUserAsCourseTeacher[course: course, user: teacher.entity_user]
    end

    it 'returns 202 for authorized teachers' do
      api_post :performance_export, teacher_token, parameters: { id: course.id }
      expect(response.status).to eq(202)
      expect(response.body_as_hash[:job]).to match(%r{/api/jobs/[a-z0-9-]+})
    end

    it 'returns the job path for the performance book export for authorized teachers' do
      api_post :performance_export, teacher_token, parameters: { id: course.id }
      expect(response.body_as_hash[:job]).to match(%r{/jobs/[a-f0-9-]+})
    end

    it 'returns 403 unauthorized users' do
      unknown = FactoryGirl.create :user_profile
      unknown_token = FactoryGirl.create :doorkeeper_access_token,
                                         resource_owner_id: unknown.id

      expect {
        api_post :performance_export, unknown_token, parameters: { id: course.id }
      }.to raise_error(SecurityTransgression)
    end

    it 'returns 404 for non-existent courses' do
      expect {
        api_post :performance_export, teacher_token, parameters: { id: 'nope' }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'GET #performance_exports' do
    let(:teacher) { FactoryGirl.create :user_profile }
    let(:teacher_token) { FactoryGirl.create :doorkeeper_access_token,
                           resource_owner_id: teacher.id }

    before do
      AddUserAsCourseTeacher[course: course, user: teacher.entity_user]
    end

    it 'returns the filename, url, timestamp of all exports for the course' do
      role = ChooseCourseRole[user: teacher.entity_user,
                              course: course,
                              allowed_role_type: :teacher]

      export = Tempfile.open(['test_export', '.xls']) do |file|
        FactoryGirl.create(:performance_report_export,
                           export: file,
                           course: course,
                           role: role)
      end

      api_get :performance_exports, teacher_token, parameters: { id: course.id }

      expect(response.status).to eq(200)
      expect(response.body_as_hash.last[:filename]).not_to include('test_export')
      expect(response.body_as_hash.last[:filename]).to include('.xls')
      expect(response.body_as_hash.last[:url]).to eq(export.url)
      expect(response.body_as_hash.last[:created_at]).not_to be_nil
    end

    it 'returns 403 for users who are not teachers of the course' do
      unknown = FactoryGirl.create :user_profile
      unknown_token = FactoryGirl.create :doorkeeper_access_token,
                                         resource_owner_id: unknown.id

      expect {
        api_get :performance_exports, unknown_token, parameters: { id: course.id }
      }.to raise_error(SecurityTransgression)
    end

    it 'returns 404 for non-existent courses' do
      expect {
        api_get :performance_exports, teacher_token, parameters: { id: 'nope' }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
