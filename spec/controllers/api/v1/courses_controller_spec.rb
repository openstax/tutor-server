require 'rails_helper'

RSpec.describe Api::V1::CoursesController, :type => :controller, :api => true, :version => :v1  do

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

  let!(:course) { Entity::CreateCourse.call.outputs.course }

  describe "#readings" do
    it "should work on the happy path" do
      root_book_part = FactoryGirl.create(:content_book_part, :standard_contents_1)
      CourseContent::Api::AddBookToCourse.call(course: course, book: root_book_part.book)

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

  describe "#plans" do
    it "should work on the happy path" do
      task_plan = FactoryGirl.create(:task_plan, owner: course)

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
    let(:roles) { Role::GetUserRoles.call(user_1).outputs.roles }
    let(:teacher) { roles.select(&:teacher?).first }
    let(:student) { roles.select(&:student?).first }

    it 'returns successfully' do
      api_get :index, user_1_token
      expect(response.code).to eq('200')
    end

    context 'user is a teacher' do
      let(:teaching) { Domain::CreateCourse.call.outputs.profile }

      before do
        Domain::AddUserAsCourseTeacher.call(course: teaching.course, user: user_1)
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
        Domain::AddUserAsCourseStudent.call(course: taking.course, user: user_1)
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
        Domain::AddUserAsCourseStudent.call(course: both.course, user: user_1)
        Domain::AddUserAsCourseTeacher.call(course: both.course, user: user_1)
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

  # let!(:student_user)       { FactoryGirl.create :user }
  # let!(:student_user_token) { FactoryGirl.create :doorkeeper_access_token, 
  #                                                application: application, 
  #                                                resource_owner_id: student_user.id }


  describe "practice_post" do
    xit "works" do
      Domain::AddUserAsCourseStudent.call(course: course, user: user_1)

      api_post :practice, user_1_token, parameters: {id: course.id, role_id: Entity::Role.last.id}

    end
  end

end
