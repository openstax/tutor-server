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

  context "POST #create" do
    let(:page) do
      page = FactoryGirl.create :content_page
      ecosystem_strategy = ::Content::Strategies::Direct::Ecosystem.new(page.ecosystem)
      ecosystem = ::Content::Ecosystem.new(strategy: ecosystem_strategy)
      AddEcosystemToCourse[course: course, ecosystem: ecosystem]
      page
    end

    let!(:exercise_1) { FactoryGirl.create :content_exercise, page: page }
    let!(:exercise_2) { FactoryGirl.create :content_exercise, page: page }
    let!(:exercise_3) { FactoryGirl.create :content_exercise, page: page }
    let!(:exercise_4) { FactoryGirl.create :content_exercise, page: page }
    let!(:exercise_5) { FactoryGirl.create :content_exercise, page: page }

    let!(:role) { AddUserAsPeriodStudent[period: period, user: user_1] }

    before(:each) do
      outs = Content::Routines::PopulateExercisePools.call(book: page.book).outputs

      OpenStax::Biglearn::Api.create_ecosystem(ecosystem: ecosystem)
    end

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

    it "returns error when no exercises can scrounged" do
      AddUserAsPeriodStudent.call(period: period, user: user_1)

      expect(OpenStax::Biglearn::Api).to(
        receive(:get_projection_exercises).once { [] }
      )

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
      api_get :show, user_1_token, parameters: { id: course.id,
                                                 role_id: Entity::Role.last.id }

      expect(response).to have_http_status(:not_found)
    end

    it "returns a practice widget" do
      AddUserAsPeriodStudent.call(period: period, user: user_1)
      ResetPracticeWidget.call(role: Entity::Role.last, exercise_source: :fake)
      ResetPracticeWidget.call(role: Entity::Role.last, exercise_source: :fake)

      api_get :show, user_1_token, parameters: { id: course.id,
                                                 role_id: Entity::Role.last.id }

      expect(response).to have_http_status(:success)

      expect(response.body_as_hash).to include(id: be_kind_of(String),
                                               title: "Practice",
                                               steps: have(5).items)
    end

    it "can be called by a teacher using a student role" do
      AddUserAsCourseTeacher.call(course: course, user: user_1)
      student_role = AddUserAsPeriodStudent[period: period, user: user_2]
      ResetPracticeWidget.call(role: student_role, exercise_source: :fake)

      api_get :show, user_1_token, parameters: { id: course.id,
                                                 role_id: student_role.id }

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
