require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::CoursesController, :type => :controller, :api => true,
                                           :version => :v1, :vcr => VCR_OPTS  do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:user_1)          { FactoryGirl.create :user }
  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: user_1.id }

  let!(:user_2)          { FactoryGirl.create :user }
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

      api_get :readings, user_1_token, parameters: {id: course.id}

      expect(response).to have_http_status(:success)
      expect(response.body_as_hash).to eq([{
        id: 2,
        title: 'unit 1',
        type: 'part',
        children: [
          {
            id: 3,
            title: 'chapter 1',
            type: 'part',
            children: [
              {
                id: 1,
                title: 'first page',
                type: 'page'
              },
              {
                id: 2,
                title: 'second page',
                type: 'page'
              }
            ]
          },
          {
            id: 4,
            title: 'chapter 2',
            type: 'part',
            children: [
              {
                id: 3,
                title: 'third page',
                type: 'page'
              }
            ]
          }
        ]
      }])

    end
  end

  describe "#exercises" do
    let!(:book) { Domain::FetchAndImportBook[
      id: '7db9aa72-f815-4c3b-9cb6-d50cf5318b58'
    ] }

    before(:each) do
      CourseContent::AddBookToCourse.call(course: course, book: book)
      Domain::AddUserAsCourseTeacher.call(course: course,
                                          user: user_1.entity_user)
    end

    it "should return an empty result if no page_ids specified" do
      api_get :exercises, user_1_token, parameters: {id: course.id}

      expect(response).to have_http_status(:success)
      expect(response.body_as_hash).to eq({total_count: 0, items: []})
    end

    it "should work on the happy path" do
      api_get :exercises, user_1_token, parameters: {id: course.id,
                                                     page_ids: [2, 3]}

      expect(response).to have_http_status(:success)
      hash = response.body_as_hash
      expect(hash[:total_count]).to eq(63)
      page_los = Content::GetPageLos[page_ids: [2, 3]]
      hash[:items].each do |item|
        wrapper = OpenStax::Exercises::V1::Exercise.new(item[:content])
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
      let(:teaching) { Domain::CreateCourse.call.outputs.profile }

      before do
        Domain::AddUserAsCourseTeacher.call(course: teaching.course, user: user_1.entity_user)
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
      let(:taking) { Domain::CreateCourse.call.outputs.profile }

      before do
        Domain::AddUserAsCourseStudent.call(course: taking.course, user: user_1.entity_user)
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
      let(:both) { Domain::CreateCourse.call.outputs.profile }

      before do
        Domain::AddUserAsCourseStudent.call(course: both.course, user: user_1.entity_user)
        Domain::AddUserAsCourseTeacher.call(course: both.course, user: user_1.entity_user)
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

  describe "practice_post" do
    it "works" do
      Domain::AddUserAsCourseStudent.call(course: course, user: user_1.entity_user)

      expect {
        api_post :practice, user_1_token, parameters: {id: course.id, role_id: Entity::Role.last.id}
      }.to change{ Tasks::Models::Task.count }.by(1)

      expect(response).to have_http_status(:success)

      expect(response.body_as_hash).to include(id: be_kind_of(Integer),
                                               title: "Practice",
                                               opens_at: be_kind_of(String),
                                               steps: have(5).items)
    end

    it "must be called by a user who belongs to the course" do
      expect{
        api_post :practice, user_1_token, parameters: {id: course.id}
      }.to raise_error(IllegalState)
    end

    it "must be called by a user who has the role" do
      Domain::AddUserAsCourseStudent.call(course: course, user: user_1.entity_user)
      expect{
        # The role belongs to user_1, we pass user_2_token
        api_post :practice, user_2_token, parameters: {id: course.id, role_id: Entity::Role.last.id}
      }.to raise_error(IllegalState)
    end

  end

  describe "practice_get" do
    it "returns nothing when practice widget not yet set" do
      Domain::AddUserAsCourseStudent.call(course: course, user: user_1.entity_user)
      api_get :practice, user_1_token, parameters: {id: course.id, role_id: Entity::Role.last.id}
      expect(response).to have_http_status(:not_found)
    end

    it "returns a practice widget" do
      Domain::AddUserAsCourseStudent.call(course: course, user: user_1.entity_user)
      Domain::ResetPracticeWidget.call(role: Entity::Role.last, condition: :fake)
      Domain::ResetPracticeWidget.call(role: Entity::Role.last, condition: :fake)

      api_get :practice, user_1_token, parameters: {id: course.id, role_id: Entity::Role.last.id}

      expect(response).to have_http_status(:success)

      expect(response.body_as_hash).to include(id: be_kind_of(Integer),
                                               title: "Practice",
                                               opens_at: be_kind_of(String),
                                               steps: have(5).items)
    end
  end

end
