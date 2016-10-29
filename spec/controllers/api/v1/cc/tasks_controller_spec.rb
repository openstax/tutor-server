require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Api::V1::Cc::TasksController, type: :controller, api: true, version: :v1 do

  before(:all) do
    chapter = FactoryGirl.create :content_chapter
    cnx_page = OpenStax::Cnx::V1::Page.new(id: '7636a3bf-eb80-4898-8b2c-e81c1711b99f',
                                           title: 'Sample module 2')
    book_location = [2, 1]

    page_model = VCR.use_cassette('Api_V1_Cc_TasksController/with_page', VCR_OPTS) do
      OpenStax::Cnx::V1.with_archive_url('https://archive.cnx.org/') do
        Content::Routines::ImportPage[chapter: chapter,
                                      cnx_page: cnx_page,
                                      book_location: book_location]
      end
    end

    @book = chapter.book
    Content::Routines::PopulateExercisePools[book: @book]

    @page = Content::Page.new(strategy: page_model.reload.wrap)

    ecosystem_model = @book.ecosystem
    ecosystem = Content::Ecosystem.new(strategy: ecosystem_model.wrap)

    period_model = FactoryGirl.create(:course_membership_period)
    period = CourseMembership::Period.new(strategy: period_model.wrap)
    @course = period.course
    @course.update_attribute(:is_concept_coach, true)

    AddEcosystemToCourse[ecosystem: ecosystem, course: @course]

    application = FactoryGirl.create :doorkeeper_application

    @user_1 = FactoryGirl.create(:user)
    @user_2 = FactoryGirl.create(:user)
    anon_user = User::User.anonymous

    @role_1 = AddUserAsPeriodStudent[user: @user_1, period: period]
    @role_2 = AddUserAsPeriodStudent[user: @user_2, period: period]

    @user_1_token = FactoryGirl.create :doorkeeper_access_token,
                                       application: application,
                                       resource_owner_id: @user_1.id
    @user_2_token = FactoryGirl.create :doorkeeper_access_token,
                                       application: application,
                                       resource_owner_id: @user_2.id
    @userless_token = FactoryGirl.create :doorkeeper_access_token,
                                         application: application,
                                         resource_owner_id: nil
    @anon_user_token = nil
  end

  def show_api_call(token, cnx_book_id: @book.uuid, cnx_page_id: @page.uuid)
    api_get :show, token, parameters: { cnx_book_id: cnx_book_id, cnx_page_id: cnx_page_id }
  end

  def stats_api_call(token, course_id: @course.id, cnx_page_id: @page.uuid)
    api_get :stats, token, parameters: { course_id: course_id, cnx_page_id: cnx_page_id }
  end

  context "#show" do
    context 'no existing task' do
      it 'should create a new task if params are valid' do
        expect{ show_api_call(@user_1_token) }.to change{ Tasks::Models::Task.count }.by(1)
        expect(response).to have_http_status(:ok)

        cc_task = Tasks::Models::Task.order(created_at: :desc).first

        expect(response.body_as_hash).to include(id: cc_task.id.to_s)
        expect(response.body_as_hash).to include(title: cc_task.title)
        expect(response.body_as_hash).to have_key(:steps)
        expect(response.body_as_hash[:steps].length).to(
          eq Tasks::Models::ConceptCoachTask::CORE_EXERCISES_COUNT
        )
      end

      it 'should return 422 with code :invalid_book if the book is invalid' do
        expect{ show_api_call(@user_1_token, cnx_book_id: 'invalid') }.not_to(
          change{ Tasks::Models::Task.count }
        )
        expect(response).to have_http_status(:unprocessable_entity)
        body = response.body_as_hash
        expect(body[:errors].map{ |error| error[:code] }).to eq ['invalid_book']
        expect(body[:valid_books]).to eq [@book.url]
      end

      it 'should return 422 with code :invalid_page if the page is invalid' do
        expect{ show_api_call(@user_1_token, cnx_page_id: 'invalid') }.not_to(
          change{ Tasks::Models::Task.count }
        )
        expect(response).to have_http_status(:unprocessable_entity)
        body = response.body_as_hash
        expect(body[:errors].map{ |error| error[:code] }).to eq ['invalid_page']
        expect(body[:valid_books]).to eq [@book.url]
      end

      it 'should return 422 with code :not_a_cc_student if the user is not in a CC course' do
        @course.update_attribute(:is_concept_coach, false)

        expect{ show_api_call(@user_1_token) }.not_to(
          change{ Tasks::Models::Task.count }
        )
        expect(response).to have_http_status(:unprocessable_entity)
        body = response.body_as_hash
        expect(body[:errors].map{ |error| error[:code] }).to eq ['not_a_cc_student']
        expect(body[:valid_books]).to eq []
      end
    end

    context 'existing task' do
      let!(:cc_task) { GetConceptCoach[user: @user_1,
                                       cnx_book_id: @book.uuid,
                                       cnx_page_id: @page.uuid] }

      it 'should not create a new task for the same user' do
        expect{ show_api_call(@user_1_token) }.not_to change{ Tasks::Models::Task.count }
        expect(response).to have_http_status(:ok)

        expect(response.body_as_hash).to include(id: cc_task.id.to_s)
      end

      it 'should create a new task for a different user' do
        expect{ show_api_call(@user_2_token) }.to change{ Tasks::Models::Task.count }.by(1)
        expect(response).to have_http_status(:ok)

        cc_task2 = Tasks::Models::Task.order{created_at.desc}.first
        expect(response.body_as_hash).to include(id: cc_task2.id.to_s)

        expect(cc_task2.id).not_to eq cc_task.id
      end

      it 'should return 422 with code invalid_book if the book is invalid' do
        expect{ show_api_call(@user_1_token, cnx_book_id: 'invalid') }.not_to(
          change{ Tasks::Models::Task.count }
        )
        expect(response).to have_http_status(:unprocessable_entity)
        body = response.body_as_hash
        expect(body[:errors].map{ |error| error[:code] }).to eq ['invalid_book']
        expect(body[:valid_books]).to eq [@book.url]
      end

      it 'should return 422 with code invalid_page if the page is invalid' do
        expect{ show_api_call(@user_1_token, cnx_page_id: 'invalid') }.not_to(
          change{ Tasks::Models::Task.count }
        )
        expect(response).to have_http_status(:unprocessable_entity)
        body = response.body_as_hash
        expect(body[:errors].map{ |error| error[:code] }).to eq ['invalid_page']
        expect(body[:valid_books]).to eq [@book.url]
      end

      it 'should return 422 with code page_has_no_exercises if the page has no exercises' do
        page = FactoryGirl.create :content_page, chapter: @book.chapters.first
        expect{ show_api_call(@user_1_token, cnx_page_id: page.uuid) }.not_to(
          change{ Tasks::Models::Task.count }
        )
        expect(response).to have_http_status(:unprocessable_entity)
        body = response.body_as_hash
        expect(body[:errors].map{ |error| error[:code] }).to eq ['page_has_no_exercises']
        expect(body[:valid_books]).to eq [@book.url]
      end
    end

    it 'returns 403 when user is not a human' do
      task_count = Tasks::Models::Task.count
      expect{ show_api_call(@userless_token) }.to raise_error(SecurityTransgression)
      expect(Tasks::Models::Task.count).to eq task_count
    end

    it 'returns 403 when user is anonymous' do
      task_count = Tasks::Models::Task.count
      expect{ show_api_call(@anon_user_token) }.to raise_error(SecurityTransgression)
      expect(Tasks::Models::Task.count).to eq task_count
    end
  end

  context '#stats' do
    it 'includes stats' do
      AddUserAsCourseTeacher[user: @user_1, course: @course]
      stats_api_call(@user_1_token)
      body = JSON.parse(response.body)
      # The representer spec does validate the json so we'll rely on it and just check presense
      expect(body['stats']).to be_a(Array)
    end

    it 'returns 403 when user is not a human' do
      expect{ stats_api_call(@userless_token) }.to raise_error(SecurityTransgression)
    end

    it 'returns 403 when user is anonymous' do
      expect{ stats_api_call(@anon_user_token) }.to raise_error(SecurityTransgression)
    end

    it 'returns 403 when user is not a course teacher' do
      expect{ stats_api_call(@user_1_token) }.to raise_error(SecurityTransgression)
    end
  end

end
