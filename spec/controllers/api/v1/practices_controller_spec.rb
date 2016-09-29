require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Api::V1::PracticesController, api: true, version: :v1 do
  let(:user_1)       { FactoryGirl.create(:user) }
  let(:user_1_token) { FactoryGirl.create :doorkeeper_access_token, resource_owner_id: user_1.id }

  let(:user_2)       { FactoryGirl.create(:user) }
  let(:user_2_token) { FactoryGirl.create :doorkeeper_access_token, resource_owner_id: user_2.id }

  let(:userless_token) { FactoryGirl.create :doorkeeper_access_token }

  let(:course) { FactoryGirl.create :course_profile_course }
  let(:period) { FactoryGirl.create :course_membership_period, course: course }

  let(:page) { FactoryGirl.create :content_page }

  let!(:exercise_1) { FactoryGirl.create :content_exercise, page: page }
  let!(:exercise_2) { FactoryGirl.create :content_exercise, page: page }
  let!(:exercise_3) { FactoryGirl.create :content_exercise, page: page }
  let!(:exercise_4) { FactoryGirl.create :content_exercise, page: page }
  let!(:exercise_5) { FactoryGirl.create :content_exercise, page: page }

  let!(:ecosystem) do
    ecosystem_strategy = ::Content::Strategies::Direct::Ecosystem.new(page.ecosystem)
    ::Content::Ecosystem.new(strategy: ecosystem_strategy).tap do |ecosystem|
      AddEcosystemToCourse[course: course, ecosystem: ecosystem]
    end
  end

  let!(:role) { AddUserAsPeriodStudent[period: period, user: user_1] }

  before(:each) do
    Content::Routines::PopulateExercisePools[book: page.book]

    OpenStax::Biglearn::Api.create_ecosystem(ecosystem: ecosystem)
  end

  context "POST #create" do
    it 'returns the practice task data' do
      api_post :create,
               user_1_token,
               parameters: { id: course.id, role_id: role.id },
               raw_post_data: { page_ids: [page.id.to_s] }.to_json

      hash = response.body_as_hash
      task = Tasks::Models::Task.last

      expect(hash).to include(id: task.id.to_s,
                              is_shared: false,
                              title: "Practice",
                              type: "page_practice",
                              steps: have(5).items)
    end

    it 'returns exercise URLs' do
      api_post :create,
               user_1_token,
               parameters: { id: course.id, role_id: role.id },
               raw_post_data: { page_ids: [page.id.to_s] }.to_json

      hash = response.body_as_hash

      step_urls = Set.new(hash[:steps].map { |s| s[:content_url] })
      exercises = [exercise_1, exercise_2, exercise_3, exercise_4, exercise_5]
      exercise_urls = Set.new(exercises.map(&:url))

      expect(step_urls).to eq exercise_urls
    end

    it "must be called by a user who belongs to the course" do
      expect{
        api_post :create,
                 user_2_token,
                 parameters: { id: course.id, role_id: role.id },
                 raw_post_data: { page_ids: [page.id.to_s] }.to_json
      }.to raise_error(SecurityTransgression)
    end

    it "returns error when no exercises can be scrounged" do
      AddUserAsPeriodStudent.call(period: period, user: user_1)

      expect(OpenStax::Biglearn::Api).to receive(:fetch_assignment_pes).and_return([])

      expect_any_instance_of(ResetPracticeWidget).to receive(:get_local_exercises).and_return([])

      api_post :create,
               user_1_token,
               parameters: { id: course.id, role_id: role.id },
               raw_post_data: { page_ids: [page.id.to_s] }.to_json

      expect(response).to have_http_status(422)
    end
  end

  context "GET #show" do
    it "returns nothing when practice widget not yet set" do
      AddUserAsPeriodStudent.call(period: period, user: user_1)
      api_get :show, user_1_token, parameters: { id: course.id, role_id: Entity::Role.last.id }

      expect(response).to have_http_status(:not_found)
    end

    it "returns a practice widget" do
      AddUserAsPeriodStudent.call(period: period, user: user_1)
      role = Entity::Role.last

      ResetPracticeWidget[role: role, exercise_source: :local, page_ids: [page.id]]
      ResetPracticeWidget[role: role, exercise_source: :local, page_ids: [page.id]]

      api_get :show, user_1_token, parameters: { id: course.id, role_id: role.id }

      expect(response).to have_http_status(:success)

      expect(response.body_as_hash).to(
        include(id: be_kind_of(String), title: "Practice", steps: have(5).items)
      )
    end

    it "can be called by a teacher using a student role" do
      AddUserAsCourseTeacher.call(course: course, user: user_1)
      student_role = AddUserAsPeriodStudent[period: period, user: user_2]
      ResetPracticeWidget[role: student_role, exercise_source: :local, page_ids: [page.id]]

      api_get :show, user_1_token, parameters: { id: course.id, role_id: student_role.id }

      expect(response).to have_http_status(:success)
    end

    it 'raises SecurityTransgression if user is anonymous or not in the course as a student' do
      expect {
        api_get :show, nil, parameters: { id: course.id }
      }.to raise_error(SecurityTransgression)

      expect {
        api_get :show, user_1_token, parameters: { id: course.id }
      }.to raise_error(SecurityTransgression)

      AddUserAsCourseTeacher.call(course: course, user: user_1)

      expect {
        api_get :show, user_1_token, parameters: { id: course.id }
      }.to raise_error(SecurityTransgression)
    end
  end
end
