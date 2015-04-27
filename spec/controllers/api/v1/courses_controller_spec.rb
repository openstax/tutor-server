require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::CoursesController, :type => :controller, :api => true,
                                           :version => :v1, :vcr => VCR_OPTS  do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:user_1)          { FactoryGirl.create :user_profile }
  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: user_1.id }

  let!(:user_2)          { FactoryGirl.create :user_profile }
  let!(:user_2_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: user_2.id }

  let!(:userless_token)  { FactoryGirl.create :doorkeeper_access_token,
                                              application: application }

  let!(:course) { Entity::Course.create! }

  describe "#readings" do
    it "should work on the happy path" do
      root_book_part = FactoryGirl.create(:content_book_part, :standard_contents_1)
      CourseContent::AddBookToCourse.call(course: course, book: root_book_part.book)
      toc = Content::VisitBook[book: root_book_part.book, visitor_names: :toc].first

      api_get :readings, user_1_token, parameters: {id: course.id}
      expect(response).to have_http_status(:success)
      expect(response.body_as_hash).to eq([{
        id: toc.id,
        title: 'unit 1',
        type: 'part',
        children: [
          {
            id: toc.children[0].id,
            title: 'chapter 1',
            type: 'part',
            children: [
              {
                id: toc.children[0].children[0].id,
                title: 'first page',
                chapter_section: '1.1',
                type: 'page'
              },
              {
                id: toc.children[0].children[1].id,
                title: 'second page',
                chapter_section: '1.2',
                type: 'page'
              }
            ]
          },
          {
            id: toc.children[1].id,
            title: 'chapter 2',
            type: 'part',
            children: [
              {
                id: toc.children[1].children[0].id,
                title: 'third page',
                chapter_section: '1.3',
                type: 'page'
              }
            ]
          }
        ]
      }])

    end
  end

  describe "#exercises" do
    let!(:book) { FetchAndImportBook[
      id: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58'
    ] }

    before(:each) do
      CourseContent::AddBookToCourse.call(course: course, book: book)
      AddUserAsCourseTeacher.call(course: course,
                                          user: user_1.entity_user)
    end

    it "should return an empty result if no page_ids specified" do
      api_get :exercises, user_1_token, parameters: {id: course.id}

      expect(response).to have_http_status(:success)
      expect(response.body_as_hash).to eq({total_count: 0, items: []})
    end

    it "should work on the happy path" do
      page_ids = Content::Models::Page.all.map(&:id)
      api_get :exercises, user_1_token, parameters: {id: course.id,
                                                     page_ids: page_ids}

      expect(response).to have_http_status(:success)
      hash = response.body_as_hash
      expect(hash[:total_count]).to eq(127)
      page_los = Content::GetLos[page_ids: page_ids]
      hash[:items].each do |item|
        wrapper = OpenStax::Exercises::V1::Exercise.new(item[:content].to_json)
        item_los = wrapper.los
        expect(item_los).not_to be_empty
        item_los.each do |item_lo|
          expect(page_los).to include(item_lo)
        end
      end
    end
  end

  describe "#plans" do
    it "should work on the happy path" do
      task_plan = FactoryGirl.create(:tasks_task_plan, owner: course)

      api_get :plans, user_1_token, parameters: {id: course.id}

      expect(response).to have_http_status(:success)
      expect(response.body).to(
        eq({ total_count: 1,
             items: [Api::V1::TaskPlanRepresenter.new(task_plan)] }.to_json)
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
          id: teaching.course.id,
          name: teaching.name,
          roles: [{ id: teacher.id, type: 'teacher' }]
        }.to_json)
      end
    end

    context 'user is a student' do
      let(:taking) { CreateCourse.call.outputs.profile }

      before do
        AddUserAsCourseStudent.call(course: taking.course, user: user_1.entity_user)
      end

      it 'returns the student roles with the course' do
        api_get :index, user_1_token
        expect(response.body).to include({
          id: taking.course.id,
          name: taking.name,
          roles: [{ id: student.id, type: 'student' }]
        }.to_json)
      end
    end

    context 'user is both a teacher and student' do
      let(:both) { CreateCourse.call.outputs.profile }

      before do
        AddUserAsCourseStudent.call(course: both.course, user: user_1.entity_user)
        AddUserAsCourseTeacher.call(course: both.course, user: user_1.entity_user)
      end

      it 'returns both roles with the course' do
        api_get :index, user_1_token
        expect(response.body).to include({
          id: both.course.id,
          name: both.name,
          roles: [{ id: student.id, type: 'student', },
                  { id: teacher.id, type: 'teacher', }]
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
      role = AddUserAsCourseStudent.call(course: course,
                                                 user: user_1.entity_user)
                                           .outputs.role

      expect {
        api_post :practice,
                 user_1_token,
                 parameters: {id: course.id, role_id: role.id},
                 raw_post_data: { page_ids: [page.id] }.to_json
      }.to change{ Tasks::Models::Task.count }.by(1)

      expect(response).to have_http_status(:success)

      hash = response.body_as_hash
      expect(hash).to include(id: be_kind_of(Integer),
                              title: "Practice",
                              opens_at: be_kind_of(String),
                              steps: have(5).items)

      step_urls = Set.new hash[:steps].collect{|s| s[:content_url]}
      exercises = [exercise_1, exercise_2, exercise_3, exercise_4, exercise_5]
      exercise_urls = Set.new exercises.collect{ |e| e.url }
      expect(step_urls).to eq exercise_urls
    end

    it "prefers unassigned exercises" do
      role = AddUserAsCourseStudent.call(course: course,
                                                 user: user_1.entity_user)
                                           .outputs.role

      # Assign the first 5 exercises
      ResetPracticeWidget.call(
        role: role, condition: :local, page_ids: [page.id]
      )

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
                 raw_post_data: { page_ids: [page.id] }.to_json
      }.to change{ Tasks::Models::Task.count }.by(1)

      expect(response).to have_http_status(:success)

      hash = response.body_as_hash
      expect(hash).to include(id: be_kind_of(Integer),
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
        api_post :practice, user_2_token, parameters: {id: course.id, role_id: Entity::Role.last.id}
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

      expect(response.body_as_hash).to include(id: be_kind_of(Integer),
                                               title: "Practice",
                                               opens_at: be_kind_of(String),
                                               steps: have(5).items)
    end
  end

end
