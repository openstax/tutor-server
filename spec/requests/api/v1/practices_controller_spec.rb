require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Api::V1::PracticesController, type: :request, api: true, version: :v1 do
  let(:user_1)         { FactoryBot.create(:user_profile) }
  let(:user_1_token)   { FactoryBot.create :doorkeeper_access_token, resource_owner_id: user_1.id }

  let(:user_2)         { FactoryBot.create(:user_profile) }
  let(:user_2_token)   { FactoryBot.create :doorkeeper_access_token, resource_owner_id: user_2.id }

  let(:userless_token) { FactoryBot.create :doorkeeper_access_token }

  let(:course)         { FactoryBot.create :course_profile_course, :without_ecosystem }
  let(:period)         { FactoryBot.create :course_membership_period, course: course }

  let(:page)           { FactoryBot.create :content_page }

  let!(:exercise_1)    { FactoryBot.create :content_exercise, page: page }
  let!(:exercise_2)    { FactoryBot.create :content_exercise, page: page }
  let!(:exercise_3)    { FactoryBot.create :content_exercise, page: page }
  let!(:exercise_4)    { FactoryBot.create :content_exercise, page: page }
  let!(:exercise_5)    { FactoryBot.create :content_exercise, page: page }

  let!(:ecosystem)     do
    page.ecosystem.tap { |ecosystem| AddEcosystemToCourse[course: course, ecosystem: ecosystem] }
  end

  let!(:role)          { AddUserAsPeriodStudent[period: period, user: user_1] }

  before(:each)        do
    Content::Routines::PopulateExercisePools[book: page.book]

    OpenStax::Biglearn::Api.create_ecosystem(ecosystem: ecosystem)
  end

  context 'POST #create' do
    it 'returns the practice task data' do
      api_post api_course_practices_url(course.id), user_1_token,
               params:  { page_ids: [ page.id.to_s ] }.to_json

      hash = response.body_as_hash
      task = Tasks::Models::Task.last

      expect(hash).to include(
        id: task.id.to_s,
        title: 'Practice',
        type: 'page_practice',
        steps: have(5).items
      )
    end

    it 'works for teacher_students' do
      AddUserAsCourseTeacher[user: user_2, course: course]
      CreateOrResetTeacherStudent[user: user_2, period: period]

      api_post api_course_practices_url(course.id), user_2_token,
               params: { page_ids: [ page.id.to_s ] }.to_json

      hash = response.body_as_hash
      task = Tasks::Models::Task.last

      expect(hash).to include(
        id: task.id.to_s,
        title: 'Practice',
        type: 'page_practice',
        steps: have(5).items
      )
    end

    it 'must be called by a user who belongs to the course' do
      expect do
        api_post api_course_practices_url(course.id), user_2_token,
                 params: { page_ids: [ page.id.to_s ] }.to_json
      end.to raise_error(SecurityTransgression)
    end

    it 'returns error when no exercises can be scrounged' do
      expect(OpenStax::Biglearn::Api).to receive(:fetch_assignment_pes).and_return(
        accepted: true,
        exercises: [],
        spy_info: {}
      )

      api_post api_course_practices_url(course.id), user_1_token,
               params: { page_ids: [ page.id.to_s ] }.to_json

      expect(response).to have_http_status(422)
    end

    it "422's if needs to pay" do
      make_payment_required_and_expect_422(course: course, user: user_1) {
        api_post api_course_practices_url(course.id), user_1_token,
                 params: { page_ids: [ page.id.to_s ] }.to_json
      }
    end
  end

  context 'POST #create_worst' do
    def create_worst_api_course_practices_url(course_id)
      "#{api_course_practices_url(course_id)}/worst"
    end

    context 'with some practice exercises' do
      let(:num_practice_exercises) { 5 }

      before do
        allow(OpenStax::Biglearn::Api).to(
          receive(:fetch_practice_worst_areas_exercises).and_return(
            accepted: true,
            exercises: num_practice_exercises.times.map { FactoryBot.create(:content_exercise) },
            spy_info: {}
          )
        )
      end

      it 'returns the practice task data' do
        api_post create_worst_api_course_practices_url(course.id), user_1_token

        hash = response.body_as_hash
        task = Tasks::Models::Task.last

        expect(hash).to include(
          id: task.id.to_s,
          title: 'Practice',
          type: 'practice_worst_topics',
          steps: have(num_practice_exercises).items
        )
      end

      it 'works for teacher_students' do
        AddUserAsCourseTeacher[user: user_2, course: course]
        CreateOrResetTeacherStudent[user: user_2, period: period]

        api_post create_worst_api_course_practices_url(course.id), user_2_token

        hash = response.body_as_hash
        task = Tasks::Models::Task.last

        expect(hash).to include(
          id: task.id.to_s,
          title: 'Practice',
          type: 'practice_worst_topics',
          steps: have(num_practice_exercises).items
        )
      end

      it 'must be called by a user who belongs to the course' do
        expect do
          api_post create_worst_api_course_practices_url(course.id), user_2_token
        end.to raise_error(SecurityTransgression)
      end

      it "422's if needs to pay" do
        make_payment_required_and_expect_422(course: course, user: user_1) do
          api_post create_worst_api_course_practices_url(course.id), user_1_token
        end
      end
    end

    context 'with no practice exercises' do
      before do
        expect(OpenStax::Biglearn::Api).to(
          receive(:fetch_practice_worst_areas_exercises).and_return(
            accepted: true,
            exercises: [],
            spy_info: {}
          )
        )
      end

      it 'returns error when no exercises can be scrounged' do
        api_post create_worst_api_course_practices_url(course.id), user_1_token

        expect(response).to have_http_status(422)
      end
    end
  end
end
