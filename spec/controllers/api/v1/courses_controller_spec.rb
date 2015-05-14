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

  let!(:course) { CreateCourse[name: 'Physics 101'] }

  describe "#readings" do
    it "should work on the happy path" do
      root_book_part = FactoryGirl.create(:content_book_part, :standard_contents_1)
      CourseContent::AddBookToCourse.call(course: course, book: root_book_part.book)
      toc = Content::VisitBook[book: root_book_part.book, visitor_names: :toc].first

      api_get :readings, user_1_token, parameters: {id: course.id}
      expect(response).to have_http_status(:success)
      expect(response.body_as_hash).to eq([{
        id: toc.id.to_s,
        title: 'unit 1',
        type: 'part',
        children: [
          {
            id: toc.children[0].id.to_s,
            title: 'chapter 1',
            type: 'part',
            children: [
              {
                id: toc.children[0].children[0].id.to_s,
                title: 'first page',
                chapter_section: [1,1],
                type: 'page'
              },
              {
                id: toc.children[0].children[1].id.to_s,
                title: 'second page',
                chapter_section: [1,2],
                type: 'page'
              }
            ]
          },
          {
            id: toc.children[1].id.to_s,
            title: 'chapter 2',
            type: 'part',
            children: [
              {
                id: toc.children[1].children[0].id.to_s,
                title: 'third page',
                chapter_section: [1,3],
                type: 'page'
              }
            ]
          }
        ]
      }])

    end
  end

  describe "#plans" do
    it "should work on the happy path" do
      task_plan = FactoryGirl.create(:tasks_task_plan, owner: course)

      api_get :plans, user_1_token, parameters: {id: course.id}

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
    let(:roles) { Role::GetUserRoles.call(user_1.entity_user).outputs.roles }
    let(:teacher) { roles.select(&:teacher?).first }
    let(:student) { roles.select(&:student?).first }

    it 'returns successfully' do
      api_get :index, user_1_token
      expect(response.code).to eq('200')
    end

    context 'user is a teacher' do
      let(:teaching) { CreateCourse.call.outputs.profile }

      before do
        AddUserAsCourseTeacher.call(course: teaching.course, user: user_1.entity_user)
      end

      it 'returns the teacher roles with the course' do
        api_get :index, user_1_token
        expect(response.body).to include({
          id: teaching.course.id.to_s,
          name: teaching.name,
          roles: [{ id: teacher.id.to_s, type: 'teacher' }]
        }.to_json)
      end
    end

    context 'user is a student' do
      let!(:taking) { CreateCourse.call.outputs.profile }

      before(:each) do
        AddUserAsCourseStudent.call(course: taking.course, user: user_1.entity_user)
      end

      it 'returns the student roles with the course' do
        api_get :index, user_1_token
        expect(response.body).to include({
          id: taking.course.id.to_s,
          name: taking.name,
          roles: [{ id: student.id.to_s, type: 'student' }]
        }.to_json)
      end
    end

    context 'user is both a teacher and student' do
      let!(:both) { CreateCourse.call.outputs.profile }

      before(:each) do
        AddUserAsCourseStudent.call(course: both.course, user: user_1.entity_user)
        AddUserAsCourseTeacher.call(course: both.course, user: user_1.entity_user)
      end

      it 'returns both roles with the course' do
        api_get :index, user_1_token
        expect(response.body).to include({
          id: both.course.id.to_s,
          name: both.name,
          roles: [{ id: student.id.to_s, type: 'student', },
                  { id: teacher.id.to_s, type: 'teacher', }]
        }.to_json)
      end
    end

    it "returns tasks for a role holder in a certain course" do
      skip "skipped until implement the real /api/courses/123/tasks endpoint with role awareness"
    end
  end

  describe "#events" do
    context "user is teacher" do
      let!(:teacher_role) {
        AddUserAsCourseTeacher.call(
          course: course,
          user:   user_1.entity_user
        ).outputs[:role]
      }

      let!(:class_entity_course) {
        class_entity_course = class_double(Entity::Course).as_stubbed_const
        allow(class_entity_course).
          to receive(:find).with(course.id.to_s).
          and_return(course)
        class_entity_course
      }

      let!(:lev_result) {
        lev_result = double(Lev::Routine::Result)
        allow(lev_result).
          to receive(:outputs).
          and_return(Hashie::Mash.new(tasks: [], plans: []))
        lev_result
      }

      let!(:get_role_course_events) {
        get_role_course_events = class_double(GetRoleCourseEvents).as_stubbed_const
        get_role_course_events
      }

      context "and not a student" do
        context "and no role is given" do
          it "should find the teacher role's events" do
            expect(get_role_course_events).
              to receive(:call).with(course: course, role: teacher_role).
              and_return(lev_result)

            api_get :events,
                    user_1_token,
                    parameters: {id: course.id}
          end
        end

        context "and the teacher role is given" do
          it "should find the teacher role's events" do
            expect(get_role_course_events).
              to receive(:call).with(course: course, role: teacher_role).
              and_return(lev_result)

            api_get :events,
                    user_1_token,
                    parameters: {id: course.id, role_id: teacher_role.id}
          end
        end
      end
      context "and also a student" do
        let!(:student_role) {
          AddUserAsCourseStudent.call(
            course: course,
            user:   user_1.entity_user
          ).outputs[:role]
        }

        context "and no role is given" do
          it "should find the teacher role's events" do
            expect(get_role_course_events).
              to receive(:call).with(course: course, role: teacher_role).
              and_return(lev_result)

            api_get :events,
                    user_1_token,
                    parameters: {id: course.id}
          end
        end
        context "and the teacher role is given" do
          it "should find the teacher role's events" do
            expect(get_role_course_events).
              to receive(:call).with(course: course, role: teacher_role).
              and_return(lev_result)

            api_get :events,
                    user_1_token,
                    parameters: {id: course.id, role_id: teacher_role.id}
          end
        end
        context "and the student role is given" do
          it "should find the student role's events" do
            expect(get_role_course_events).
              to receive(:call).with(course: course, role: student_role).
              and_return(lev_result)

            api_get :events,
                    user_1_token,
                    parameters: {id: course.id, role_id: student_role.id}
          end
        end
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

    it "works" do
      role = AddUserAsCourseStudent.call(course: course, user: user_1.entity_user).outputs.role

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

    it "prefers unassigned exercises" do
      role = AddUserAsCourseStudent.call(course: course, user: user_1.entity_user).outputs.role

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
      AddUserAsCourseStudent.call(course: course, user: user_1.entity_user)
      expect{
        # The role belongs to user_1, we pass user_2_token
        api_post :practice, user_2_token, parameters: {id: course.id,
                                                       role_id: Entity::Role.last.id}
      }.to raise_error(IllegalState)
    end

  end

  describe "practice_get" do
    it "returns nothing when practice widget not yet set" do
      AddUserAsCourseStudent.call(course: course, user: user_1.entity_user)
      api_get :practice, user_1_token, parameters: {id: course.id, role_id: Entity::Role.last.id}

      expect(response).to have_http_status(:not_found)
    end

    it "returns a practice widget" do
      AddUserAsCourseStudent.call(course: course, user: user_1.entity_user)
      ResetPracticeWidget.call(role: Entity::Role.last, condition: :fake)
      ResetPracticeWidget.call(role: Entity::Role.last, condition: :fake)

      api_get :practice, user_1_token, parameters: {id: course.id, role_id: Entity::Role.last.id}

      expect(response).to have_http_status(:success)

      expect(response.body_as_hash).to include(id: be_kind_of(String),
                                               title: "Practice",
                                               opens_at: be_kind_of(String),
                                               steps: have(5).items)
    end
  end

  describe "dashboard" do
    let!(:student_profile){ FactoryGirl.create(:user_profile) }
    let!(:student_user)   { student_profile.entity_user }
    let!(:student_role)   { AddUserAsCourseStudent.call(user: student_user,
                                                        course: course)
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

    let!(:plan) { FactoryGirl.create(:tasks_task_plan, owner: course)}

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
            "opens_at" => be_kind_of(String),
            "due_at" => be_kind_of(String),
            "type" => "reading"
          )
        )
      )
    end

  end

  context 'with book' do
    before(:all) do
      DatabaseCleaner.start

      VCR.use_cassette("Api_V1_CoursesController/with_book", VCR_OPTS) do
        @book = FetchAndImportBook[id: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58']
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
        expect(hash[:total_count]).to eq(128)
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
      let(:student_1) { FactoryGirl.create :user_profile }
      let(:student_1_token) { FactoryGirl.create :doorkeeper_access_token,
                                resource_owner_id: student_1.id }

      before do
        SetupPerformanceBookData[course: course,
                                 teacher: teacher,
                                 students: student_1,
                                 book: @book]
      end

      it 'should work on the happy path' do
        api_get :performance, teacher_token, parameters: { id: course.id }

        expect(response).to have_http_status :success
        expect(response.body_as_hash).to include(
          data_headings: [
            { title: 'Homework task plan', class_average: 75.0 },
            { title: 'Reading task plan' },
            { title: 'Homework 2 task plan' }
          ],
          students: [{
            name: kind_of(String),
            role: kind_of(Integer),
            data: [
              {
                type: 'homework',
                id: kind_of(Integer),
                status: 'completed',
                exercise_count: 6,
                correct_exercise_count: 6,
                recovered_exercise_count: 0
              },
              {
                type: 'reading',
                id: kind_of(Integer),
                status: 'completed'
              },
              {
                type: 'homework',
                id: kind_of(Integer),
                status: 'not_started',
                exercise_count: 4,
                correct_exercise_count: 0,
                recovered_exercise_count: 0
              }
            ]
          }, {
            name: kind_of(String),
            role: kind_of(Integer),
            data: [
              {
                type: 'homework',
                id: kind_of(Integer),
                status: 'in_progress',
                exercise_count: 6,
                correct_exercise_count: 2,
                recovered_exercise_count: 0
              },
              {
                type: 'reading',
                id: kind_of(Integer),
                status: 'in_progress'
              },
              {
                type: 'homework',
                id: kind_of(Integer),
                status: 'not_started',
                exercise_count: 4,
                correct_exercise_count: 0,
                recovered_exercise_count: 0
              }
            ]
          }]
        )
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

    it 'returns 201 for authorized teachers' do
      api_post :performance_export, teacher_token, parameters: { id: course.id }

      expect(response.status).to eq(201)
    end

    it 'kicks off the performance book export for authorized teachers' do
      role = ChooseCourseRole[course: course, user: teacher.entity_user]
      allow(Queues::ExportPerformanceBook).to receive(:[])

      api_post :performance_export, teacher_token, parameters: { id: course.id }

      expect(Queues::ExportPerformanceBook).to have_received(:[])
        .with(course: course, role: role)
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
      export = FactoryGirl.create(:performance_book_export,
                                  export: File.open('./tmp/test.txt', 'w+'),
                                  course: course,
                                  role: role)

      api_get :performance_exports, teacher_token, parameters: { id: course.id }

      expect(response.status).to eq(200)
      expect(response.body_as_hash.last[:filename]).to eq('test.txt')
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
