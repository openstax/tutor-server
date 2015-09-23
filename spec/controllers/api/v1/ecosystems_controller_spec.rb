require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Api::V1::EcosystemsController, type: :controller, api: true,
                                              version: :v1, speed: :slow, vcr: VCR_OPTS do

  let!(:user_1)             {
    profile = FactoryGirl.create(:user_profile)
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }
  let!(:user_1_token)       { FactoryGirl.create :doorkeeper_access_token,
                                                 resource_owner_id: user_1.id }

  let!(:user_2)             {
    profile = FactoryGirl.create(:user_profile)
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }
  let!(:user_2_token)       { FactoryGirl.create :doorkeeper_access_token,
                                                 resource_owner_id: user_2.id }

  let!(:userless_token)  { FactoryGirl.create :doorkeeper_access_token }

  let!(:course)          { CreateCourse[name: 'Physics 101'] }
  let!(:period)          { CreatePeriod[course: course] }

  context 'with a fake book' do
    let!(:book)            { FactoryGirl.create(:content_book, :standard_contents_1) }
    let!(:ecosystem)       {
      strategy = Content::Strategies::Direct::Ecosystem.new(book.ecosystem.reload)
      ecosystem = Content::Ecosystem.new(strategy: strategy)
      CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: ecosystem)
      ecosystem
    }

    describe "#readings" do
      it 'raises SecurityTransgression if user is anonymous or not in the course' do
        expect {
          api_get :readings, nil, parameters: { id: ecosystem.id }
        }.to raise_error(SecurityTransgression)

        expect {
          api_get :readings, user_1_token, parameters: { id: ecosystem.id }
        }.to raise_error(SecurityTransgression)
      end

      it 'works for students in the course' do
        AddUserAsCourseTeacher.call(course: course, user: user_1)
        AddUserAsPeriodStudent.call(period: period, user: user_2)

        api_get :readings, user_1_token, parameters: { id: ecosystem.id }
        expect(response).to have_http_status(:success)
        teacher_response = response.body_as_hash

        api_get :readings, user_2_token, parameters: { id: ecosystem.id }
        expect(response).to have_http_status(:success)
        student_response = response.body_as_hash

        expect(teacher_response).to eq(student_response)
      end

      it "should work on the happy path" do
        AddUserAsCourseTeacher.call(course: course, user: user_1)

        api_get :readings, user_1_token, parameters: {id: ecosystem.id}
        expect(response).to have_http_status(:success)
        expect(response.body_as_hash).to eq([{
          id: ecosystem.books.first.id.to_s,
          cnx_id: ecosystem.books.first.cnx_id,
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
                  cnx_id: ecosystem.books.first.chapters.first.pages.first.cnx_id,
                  title: 'first page',
                  chapter_section: [1, 1],
                  type: 'page'
                },
                {
                  id: ecosystem.books.first.chapters.first.pages.second.id.to_s,
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
      DatabaseCleaner.start

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

    after(:all) do
      DatabaseCleaner.clean
    end

    describe "#exercises" do
      it 'raises SecurityTransgression if user is anonymous or not a teacher' do
        page_ids = Content::Models::Page.all.map(&:id)

        expect {
          api_get :exercises, nil, parameters: { id: @ecosystem.id, page_ids: page_ids }
        }.to raise_error(SecurityTransgression)

        expect {
          api_get :exercises, user_2_token, parameters: { id: @ecosystem.id, page_ids: page_ids }
        }.to raise_error(SecurityTransgression)
      end

      it "should return an empty result if no page_ids specified" do
        api_get :exercises, user_1_token, parameters: { id: @ecosystem.id }

        expect(response).to have_http_status(:success)
        expect(response.body_as_hash).to eq({total_count: 0, items: []})
      end

      it "should work on the happy path" do
        page_ids = Content::Models::Page.all.map(&:id)
        api_get :exercises, user_1_token, parameters: { id: @ecosystem.id, page_ids: page_ids}

        expect(response).to have_http_status(:success)
        hash = response.body_as_hash
        expect(hash[:total_count]).to eq(70)
        page_los = Content::Models::Page.all.map(&:los).flatten.collect(&:value)
        hash[:items].each do |item|
          wrapper = OpenStax::Exercises::V1::Exercise.new(content: item[:content].to_json)
          item_los = wrapper.los
          expect(item_los).not_to be_empty
          item_los.each do |item_lo|
            expect(page_los).to include(item_lo)
          end
        end
      end
    end
  end

end
