require 'rails_helper'
require 'vcr_helper'
require 'database_cleaner'

RSpec.describe Api::V1::ContentsController, type: :controller, api: true,
                                            version: :v1, speed: :slow, vcr: VCR_OPTS do

  let!(:user_1)          { FactoryGirl.create :user_profile }
  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              resource_owner_id: user_1.id }

  let!(:user_2)          { FactoryGirl.create :user_profile }
  let!(:user_2_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              resource_owner_id: user_2.id }

  let!(:userless_token)  { FactoryGirl.create :doorkeeper_access_token }

  let!(:course)          { CreateCourse[name: 'Physics 101'] }
  let!(:period)          { CreatePeriod[course: course] }

  def add_book_to_course(course: course)
    book = FactoryGirl.create(:content_book, :standard_contents_1)
    content_ecosystem = book.ecosystem.reload
    strategy = Content::Strategies::Direct::Ecosystem.new(content_ecosystem)
    ecosystem = Content::Ecosystem.new(strategy: strategy)
    CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: ecosystem)

    { book: book, ecosystem: ecosystem }
  end

  describe "#course_readings" do
    it 'raises SecurityTransgression if user is anonymous or not in the course' do
      add_book_to_course(course: course)

      expect {
        api_get :course_readings, nil, parameters: { id: course.id }
      }.to raise_error(SecurityTransgression)

      expect {
        api_get :course_readings, user_1_token, parameters: { id: course.id }
      }.to raise_error(SecurityTransgression)
    end

    it 'works for students in the course' do
      # used in FE for reference view
      add_book_to_course(course: course)
      AddUserAsCourseTeacher.call(course: course, user: user_1.entity_user)
      AddUserAsPeriodStudent.call(period: period, user: user_2.entity_user)

      api_get :course_readings, user_1_token, parameters: { id: course.id }
      expect(response).to have_http_status(:success)
      teacher_response = response.body_as_hash

      api_get :course_readings, user_2_token, parameters: { id: course.id }
      expect(response).to have_http_status(:success)
      student_response = response.body_as_hash

      expect(teacher_response).to eq(student_response)
    end

    it "should work on the happy path" do
      ecosystem = add_book_to_course(course: course)[:ecosystem]
      CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: ecosystem)
      AddUserAsCourseTeacher.call(course: course, user: user_1.entity_user)

      api_get :course_readings, user_1_token, parameters: {id: course.id}
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

  context 'with book' do
    before(:all) do
      DatabaseCleaner.start

      VCR.use_cassette("Api_V1_ContentsController/with_book", VCR_OPTS) do
        @ecosystem = FetchAndImportBookAndCreateEcosystem[
          id: '93e2b09d-261c-4007-a987-0b3062fe154b'
        ]
      end
    end

    before(:each) do
      CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: @ecosystem)
    end

    after(:all) do
      DatabaseCleaner.clean
    end

    describe "#course_exercises" do
      before(:each) do
        AddUserAsCourseTeacher.call(course: course, user: user_1.entity_user)
      end

      it 'raises SecurityTransgression if user is anonymous or not a teacher' do
        page_ids = Content::Models::Page.all.map(&:id)

        expect {
          api_get :course_exercises, nil, parameters: { id: course.id, page_ids: page_ids }
        }.to raise_error(SecurityTransgression)

        expect {
          api_get :course_exercises, user_2_token, parameters: { id: course.id,
                                                                 page_ids: page_ids }
        }.to raise_error(SecurityTransgression)
      end

      it "should return an empty result if no page_ids specified" do
        api_get :course_exercises, user_1_token, parameters: { id: course.id }

        expect(response).to have_http_status(:success)
        expect(response.body_as_hash).to eq({total_count: 0, items: []})
      end

      it "should work on the happy path" do
        page_ids = Content::Models::Page.all.map(&:id)
        api_get :course_exercises, user_1_token, parameters: {id: course.id, page_ids: page_ids}

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
