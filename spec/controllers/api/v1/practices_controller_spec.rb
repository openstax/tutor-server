require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Api::V1::PracticesController, api: true, version: :v1,
                                             speed: :slow, vcr: VCR_OPTS do
  let(:user_1) { FactoryGirl.create :user_profile }
  let(:user_1_token) { FactoryGirl.create :doorkeeper_access_token,
                                          resource_owner_id: user_1.id }

  let(:user_2) { FactoryGirl.create :user_profile }
  let(:user_2_token) { FactoryGirl.create :doorkeeper_access_token,
                                          resource_owner_id: user_2.id }

  let(:userless_token) { FactoryGirl.create :doorkeeper_access_token }

  let(:course) { CreateCourse[name: 'Physics 101'] }
  let(:period) { CreatePeriod[course: course] }

  describe "POST #create" do
    let(:lo) { FactoryGirl.create :content_tag, tag_type: :lo, value: 'lo01' }
    let(:page) { FactoryGirl.create :content_page }
    let!(:page_tag) { FactoryGirl.create :content_page_tag, page: page, tag: lo }

    let(:exercise_1) { FactoryGirl.create :content_exercise }
    let(:exercise_2) { FactoryGirl.create :content_exercise }
    let(:exercise_3) { FactoryGirl.create :content_exercise }
    let(:exercise_4) { FactoryGirl.create :content_exercise }
    let(:exercise_5) { FactoryGirl.create :content_exercise }

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

    let!(:role) { AddUserAsPeriodStudent[period: period, user: user_1.entity_user] }

    it 'returns the practice task data' do
      api_post :create,
               user_1_token,
               parameters: { course_id: course.id, role_id: role.id },
               raw_post_data: { page_ids: [page.id.to_s] }.to_json

      hash = response.body_as_hash
      task = Tasks::Models::Task.last

      expect(hash).to include(id: "#{task.id}",
                              is_shared: false,
                              opens_at: DateTimeUtilities.to_api_s(task.opens_at),
                              title: "Practice",
                              type: "chapter_practice",
                              steps: have(5).items)
    end

    it 'returns exercise URLs' do
      api_post :create,
               user_1_token,
               parameters: { course_id: course.id, role_id: role.id },
               raw_post_data: { page_ids: [page.id.to_s] }.to_json

      hash = response.body_as_hash

      step_urls = Set.new(hash[:steps].collect { |s| s[:content_url] })
      exercises = [exercise_1, exercise_2, exercise_3, exercise_4, exercise_5]
      exercise_urls = Set.new(exercises.collect(&:url))

      expect(step_urls).to eq exercise_urls
    end

    it "prefers unassigned exercises" do
      # Assign the first 5 exercises
      ResetPracticeWidget[role: role, exercise_source: :local, page_ids: [page.id]]

      # Then add 3 more to be assigned
      exercise_6 = FactoryGirl.create :content_exercise
      exercise_7 = FactoryGirl.create :content_exercise
      exercise_8 = FactoryGirl.create :content_exercise

      FactoryGirl.create :content_exercise_tag, exercise: exercise_6, tag: lo
      FactoryGirl.create :content_exercise_tag, exercise: exercise_7, tag: lo
      FactoryGirl.create :content_exercise_tag, exercise: exercise_8, tag: lo

      api_post :create,
               user_1_token,
               parameters: { course_id: course.id, role_id: role.id },
               raw_post_data: { page_ids: [page.id.to_s] }.to_json

      hash = response.body_as_hash
      step_urls = Set.new hash[:steps].collect{|s| s[:content_url]}

      expect(step_urls).to include(exercise_6.url)
      expect(step_urls).to include(exercise_7.url)
      expect(step_urls).to include(exercise_8.url)

      exercises = [exercise_1, exercise_2, exercise_3, exercise_4,
                   exercise_5, exercise_6, exercise_7, exercise_8]
      exercise_urls = Set.new exercises.collect(&:url)

      expect(step_urls.proper_subset?(exercise_urls)).to eq true
    end

    it "must be called by a user who belongs to the course" do
      expect{
        api_post :create,
                 user_2_token,
                 parameters: { course_id: course.id, role_id: role.id },
                 raw_post_data: { page_ids: [page.id.to_s] }.to_json
      }.to raise_error(IllegalState)
    end
  end

  describe "GET #show" do
    it "returns nothing when practice widget not yet set" do
      AddUserAsPeriodStudent.call(period: period, user: user_1.entity_user)
      api_get :show, user_1_token, parameters: { course_id: course.id,
                                                 role_id: Entity::Role.last.id }

      expect(response).to have_http_status(:not_found)
    end

    it "returns a practice widget" do
      AddUserAsPeriodStudent.call(period: period, user: user_1.entity_user)
      ResetPracticeWidget.call(role: Entity::Role.last, exercise_source: :fake)
      ResetPracticeWidget.call(role: Entity::Role.last, exercise_source: :fake)

      api_get :show, user_1_token, parameters: { course_id: course.id,
                                                 role_id: Entity::Role.last.id }

      expect(response).to have_http_status(:success)

      expect(response.body_as_hash).to include(id: be_kind_of(String),
                                               title: "Practice",
                                               opens_at: be_kind_of(String),
                                               steps: have(5).items)
    end

    it "can be called by a teacher using a student role" do
      AddUserAsCourseTeacher.call(course: course, user: user_1.entity_user)
      student_role = AddUserAsPeriodStudent[period: period, user: user_2.entity_user]
      ResetPracticeWidget.call(role: student_role, exercise_source: :fake)

      api_get :show, user_1_token, parameters: { course_id: course.id,
                                                 role_id: student_role.id }

      expect(response).to have_http_status(:success)
    end

    it 'raises IllegalState if user is anonymous or not in the course or is not a student' do
      expect {
        api_get :show, nil, parameters: { course_id: course.id }
      }.to raise_error(IllegalState)

      expect {
        api_get :show, user_1_token, parameters: { course_id: course.id }
      }.to raise_error(IllegalState)

      AddUserAsCourseTeacher.call(course: course, user: user_1.entity_user)

      expect {
        api_get :show, user_1_token, parameters: { course_id: course.id }
      }.to raise_error(IllegalState)
    end
  end
end
