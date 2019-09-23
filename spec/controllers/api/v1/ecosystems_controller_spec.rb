require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Api::V1::EcosystemsController, type: :controller, api: true,
                                              version: :v1, vcr: VCR_OPTS, speed: :slow do

  let(:user_1)          { FactoryBot.create(:user) }
  let(:user_1_token)    { FactoryBot.create :doorkeeper_access_token,
                                             resource_owner_id: user_1.id }

  let(:user_2)          { FactoryBot.create(:user) }
  let(:user_2_token)    { FactoryBot.create :doorkeeper_access_token,
                                             resource_owner_id: user_2.id }

  let(:userless_token)  { FactoryBot.create :doorkeeper_access_token }

  let(:content_analyst) { FactoryBot.create(:user, :content_analyst) }

  let(:ca_user_token)   { FactoryBot.create :doorkeeper_access_token,
                                             resource_owner_id: content_analyst.id }

  let(:course)          { FactoryBot.create :course_profile_course }
  let(:period)          { FactoryBot.create :course_membership_period, course: course }

  context 'with a fake book' do
    let(:book)          { FactoryBot.create(:content_book, :standard_contents_1) }
    let!(:ecosystem)    {
      strategy = Content::Strategies::Direct::Ecosystem.new(book.ecosystem.reload)
      ecosystem = Content::Ecosystem.new(strategy: strategy)
      CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: ecosystem)
      ecosystem
    }

    context '#index' do
      it 'raises SecurityTransgression unless user is a content analyst' do
        expect {
          api_get :index, nil
        }.to raise_error(SecurityTransgression)

        expect {
          api_get :index, user_2_token
        }.to raise_error(SecurityTransgression)
      end

      it 'allows a content analyst to access' do
        expect {
          api_get :index, ca_user_token
        }.not_to raise_error
      end
    end

    context "#readings" do
      it 'raises SecurityTransgression if user is anonymous or not in the course' do
        expect {
          api_get :readings, nil, params: { id: ecosystem.id }
        }.to raise_error(SecurityTransgression)

        expect {
          api_get :readings, user_1_token, params: { id: ecosystem.id }
        }.to raise_error(SecurityTransgression)
      end

      it 'works for students in the course' do
        AddUserAsCourseTeacher.call(course: course, user: user_1)
        AddUserAsPeriodStudent.call(period: period, user: user_2)

        api_get :readings, user_1_token, params: { id: ecosystem.id }
        expect(response).to have_http_status(:success)
        teacher_response = response.body_as_hash

        api_get :readings, user_2_token, params: { id: ecosystem.id }
        expect(response).to have_http_status(:success)
        student_response = response.body_as_hash

        expect(teacher_response).to eq(student_response)
      end

      it "works for teachers in the course" do
        AddUserAsCourseTeacher.call(course: course, user: user_1)

        api_get :readings, user_1_token, params: {id: ecosystem.id}
        expect(response).to have_http_status(:success)
        expect(response.body_as_hash).to eq([{
          id: ecosystem.books.first.id.to_s,
          uuid: ecosystem.books.first.uuid,
          cnx_id: ecosystem.books.first.cnx_id,
          archive_url: "https://archive.cnx.org",
          webview_url: "https://cnx.org",
          is_collated: false,
          title: 'book title',
          type: 'part',
          chapter_section: [],
          children: [
            {
              id: ecosystem.books.first.chapters.first.id.to_s,
              title: 'chapter 1',
              type: 'part',
              chapter_section: [1],
              children: [
                {
                  id: ecosystem.books.first.chapters.first.pages.first.id.to_s,
                  uuid: ecosystem.books.first.chapters.first.pages.first.uuid,
                  cnx_id: ecosystem.books.first.chapters.first.pages.first.cnx_id,
                  title: 'first page',
                  chapter_section: [1, 1],
                  type: 'page'
                },
                {
                  id: ecosystem.books.first.chapters.first.pages.second.id.to_s,
                  uuid: ecosystem.books.first.chapters.first.pages.second.uuid,
                  cnx_id: ecosystem.books.first.chapters.first.pages.second.cnx_id,
                  title: 'second page',
                  chapter_section: [1, 2],
                  type: 'page'
                }
              ]
            },
            {
              id: ecosystem.books.first.chapters.second.id.to_s,
              title: 'chapter 2',
              type: 'part',
              chapter_section: [2],
              children: [
                {
                  id: ecosystem.books.first.chapters.second.pages.first.id.to_s,
                  uuid: ecosystem.books.first.chapters.second.pages.first.uuid,
                  cnx_id: ecosystem.books.first.chapters.second.pages.first.cnx_id,
                  title: 'third page',
                  chapter_section: [2, 1],
                  type: 'page'
                }
              ]
            }
          ]
        }])

      end
    end
  end

  context 'with a real book' do
    before(:all) do
      VCR.use_cassette("Api_V1_EcosystemsController/with_book", VCR_OPTS) do
        @ecosystem = FetchAndImportBookAndCreateEcosystem[
          book_cnx_id: '93e2b09d-261c-4007-a987-0b3062fe154b'
        ]
      end
    end

    before(:each) do
      CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: @ecosystem)
      AddUserAsCourseTeacher.call(course: course, user: user_1)
    end

    context "#exercises" do
      it 'raises SecurityTransgression if user is anonymous or not a teacher' do
        page_ids = Content::Models::Page.all.map(&:id)

        expect {
          api_get :exercises, nil, params: { id: @ecosystem.id, page_ids: page_ids }
        }.to raise_error(SecurityTransgression)

        expect {
          api_get :exercises, user_2_token, params: { id: @ecosystem.id, page_ids: page_ids }
        }.to raise_error(SecurityTransgression)
      end

      it "should return all exercises if page_ids is ommitted" do
        api_get :exercises, user_1_token, params: { id: @ecosystem.id }

        expect(response).to have_http_status(:success)
        expect(response.body_as_hash[:total_count]).to eq(@ecosystem.exercises.size)
      end

      it "works for teachers in the course" do
        page_ids = Content::Models::Page.all.map(&:id)
        api_get :exercises, user_1_token, params: { id: @ecosystem.id, page_ids: page_ids}

        expect(response).to have_http_status(:success)
        hash = response.body_as_hash
        expect(hash[:total_count]).to eq(215)
        hash[:items].each do |item|
          expect(item[:pool_types]).not_to be_empty
          wrapper = OpenStax::Exercises::V1::Exercise.new(content: item[:content].to_json)
          item_los = wrapper.los
          expect(item_los).not_to be_empty
        end
      end

      it "returns exercise exclusion information if a course_id is given" do
        page_ids = Content::Models::Page.all.map(&:id)
        api_get :exercises, user_1_token, params: {
          id: @ecosystem.id, page_ids: page_ids, course_id: course.id
        }

        expect(response).to have_http_status(:success)
        hash = response.body_as_hash
        expect(hash[:total_count]).to eq(215)
        hash[:items].each do |item|
          expect(item[:is_excluded]).to eq false
        end
      end

      it "returns only exercises in certain pools if pool_types are given" do
        page_ids = Content::Models::Page.all.map(&:id)
        api_get :exercises, user_1_token, params: {
          id: @ecosystem.id, page_ids: page_ids, pool_types: 'homework_core'
        }

        expect(response).to have_http_status(:success)
        hash = response.body_as_hash
        expect(hash[:total_count]).to eq(70)
        hash[:items].each do |item|
          expect(item[:pool_types]).to eq ['homework_core']
          wrapper = OpenStax::Exercises::V1::Exercise.new(content: item[:content].to_json)
          item_los = wrapper.los
          expect(item_los).not_to be_empty
        end
      end
    end
  end

end
