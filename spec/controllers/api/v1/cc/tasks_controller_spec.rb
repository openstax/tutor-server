require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Api::V1::Cc::TasksController, type: :controller, api: true, version: :v1 do

  before(:all) do
    DatabaseCleaner.start

    chapter = FactoryGirl.create :content_chapter
    cnx_page = OpenStax::Cnx::V1::Page.new(id: '95e61258-2faf-41d4-af92-f62e1414175a',
                                           title: 'Force')
    book_location = [4, 1]

    page_model = VCR.use_cassette('Api_V1_Cc_TasksController/with_page', VCR_OPTS) do
      Content::Routines::ImportPage[chapter: chapter,
                                    cnx_page: cnx_page,
                                    book_location: book_location]
    end

    @book = chapter.book
    Content::Routines::PopulateExercisePools[book: @book]

    @page = Content::Page.new(strategy: page_model.reload.wrap)

    ecosystem_model = @book.ecosystem
    ecosystem = Content::Ecosystem.new(strategy: ecosystem_model.wrap)

    period_model = FactoryGirl.create(:course_membership_period)
    period = CourseMembership::Period.new(strategy: period_model.wrap)

    AddEcosystemToCourse[ecosystem: ecosystem, course: period.course]

    application = FactoryGirl.create :doorkeeper_application

    user_1 = FactoryGirl.create(:user)
    user_2 = FactoryGirl.create(:user)
    anon_user = User::User.anonymous

    @role_1 = AddUserAsPeriodStudent[user: user_1, period: period]
    @role_2 = AddUserAsPeriodStudent[user: user_2, period: period]

    @book_uuid = @book.uuid
    @page_uuid = @page.uuid

    @user_1_token = FactoryGirl.create :doorkeeper_access_token,
                                       application: application,
                                       resource_owner_id: user_1.id
    @user_2_token = FactoryGirl.create :doorkeeper_access_token,
                                       application: application,
                                       resource_owner_id: user_2.id
    @userless_token = FactoryGirl.create :doorkeeper_access_token,
                                         application: application,
                                         resource_owner_id: nil
    @anon_user_token = nil
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  def api_call(token, cnx_book_id: @book_uuid, cnx_page_id: @page_uuid)
    api_get :show, token, parameters: { cnx_book_id: cnx_book_id, cnx_page_id: cnx_page_id }
  end

  describe "#show" do
    context 'no existing task' do
      it 'should create a new task if params are valid' do
        expect{ api_call(@user_1_token) }.to change{ Tasks::Models::Task.count }.by(1)
        expect(response).to have_http_status(:ok)

        cc_task = Tasks::Models::Task.order(created_at: :desc).first

        expect(response.body_as_hash).to include(id: cc_task.id.to_s)
        expect(response.body_as_hash).to include(title: cc_task.title)
        expect(response.body_as_hash).to have_key(:steps)
        expect(response.body_as_hash[:steps].length).to eq 4
      end

      it 'should return 422 with code :invalid_book if the book is invalid' do
        expect{ api_call(@user_1_token, cnx_book_id: 'invalid') }.not_to(
          change{ Tasks::Models::Task.count }
        )
        expect(response).to have_http_status(:unprocessable_entity)
        body = response.body_as_hash
        expect(body[:errors].map{ |error| error[:code] }).to eq ['invalid_book']
        expect(body[:valid_books]).to eq [@book.url]
      end

      it 'should return 422 with code :invalid_page if the page is invalid' do
        expect{ api_call(@user_1_token, cnx_page_id: 'invalid') }.not_to(
          change{ Tasks::Models::Task.count }
        )
        expect(response).to have_http_status(:unprocessable_entity)
        body = response.body_as_hash
        expect(body[:errors].map{ |error| error[:code] }).to eq ['invalid_page']
        expect(body[:valid_books]).to eq [@book.url]
      end

      it 'should return 422 with code :not_a_cc_student if the user is not in a CC course' do
        @role_1.destroy
        expect{ api_call(@user_1_token) }.not_to(
          change{ Tasks::Models::Task.count }
        )
        expect(response).to have_http_status(:unprocessable_entity)
        body = response.body_as_hash
        expect(body[:errors].map{ |error| error[:code] }).to eq ['not_a_cc_student']
        expect(body[:valid_books]).to eq []
      end
    end

    context 'existing task' do
      let!(:cc_task) { GetConceptCoach[role: @role_1, page: @page].task }

      it 'should not create a new task for the same user' do
        expect{ api_call(@user_1_token) }.not_to change{ Tasks::Models::Task.count }
        expect(response).to have_http_status(:ok)

        expect(response.body_as_hash).to include(id: cc_task.id.to_s)
      end

      it 'should create a new task for a different user' do
        expect{ api_call(@user_2_token) }.to change{ Tasks::Models::Task.count }.by(1)
        expect(response).to have_http_status(:ok)

        cc_task2 = Tasks::Models::Task.order{created_at.desc}.first
        expect(response.body_as_hash).to include(id: cc_task2.id.to_s)

        expect(cc_task2.id).not_to eq cc_task.id
      end
    end

    it 'returns 403 when user is not a human' do
      task_count = Tasks::Models::Task.count
      expect{ api_call(@userless_token) }.to raise_error(SecurityTransgression)
      expect(Tasks::Models::Task.count).to eq task_count
    end

    it 'returns 403 when user is anonymous' do
      task_count = Tasks::Models::Task.count
      expect{ api_call(@anon_user_token) }.to raise_error(SecurityTransgression)
      expect(Tasks::Models::Task.count).to eq task_count
    end
  end

end
