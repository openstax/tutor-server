require 'rails_helper'

RSpec.describe CustomerService::CoursesController, type: :request do
  let(:customer_service) { FactoryBot.create(:user_profile, :customer_service) }

  before                 { sign_in! customer_service }

  context 'GET #index' do
    it 'assigns all CollectCourseInfo output to @course_infos' do
      FactoryBot.create :course_profile_course, name: 'Hello World'

      get customer_service_courses_url

      expect(assigns[:course_infos].count).to eq(1)
      expect(assigns[:course_infos].first.name).to eq('Hello World')
    end

    it 'passes the query param to SearchCourses along with order_by params' do
      expect(SearchCourses).to receive(:call).with(
        query: 'test', order_by: 'name'
      ).once.and_call_original
      get customer_service_courses_url, params: { query: 'test', order_by: 'name' }
    end

    context "pagination" do
      context "when the are any results" do
        before do
          4.times {FactoryBot.create(:course_profile_course, name: "Algebra #{rand(1000)}")}
          expect(CourseProfile::Models::Course.count).to eq(4)
        end

        it "paginates the results" do
          get customer_service_courses_url, params: { page: 1, per_page: 2 }
          expect(assigns[:course_infos].length).to eq(2)
        end

        it "can access other pages" do
          get customer_service_courses_url, params: { page: 2, per_page: 2 }
          expect(assigns[:course_infos].length).to eq(2)
        end
      end

      context "when there are no results" do
        it "doesn't blow up" do
          expect(CourseProfile::Models::Course.count).to eq(0)

          get customer_service_courses_url, params: { page: 1 }
          expect(response).to have_http_status :ok
        end
      end
    end
  end

  context 'GET #show' do
    it 'assigns extra course info' do
      course = FactoryBot.create :course_profile_course, name: 'Hello World'

      get customer_service_course_url(course.id)

      expect(assigns[:course].id).to eq course.id
      expect(Set.new assigns[:periods]).to eq Set.new course.periods
      expect(Set.new assigns[:teachers]).to eq Set.new course.teachers
    end
  end

  context 'disallowing baddies' do
    it 'disallows unauthenticated visitors' do
      sign_out!

      get customer_service_courses_url
      expect(response).not_to be_successful

      get customer_service_course_url(1)
      expect(response).not_to be_successful
    end

    it 'disallows non-customer-service authenticated visitors' do
      sign_in! FactoryBot.create(:user_profile)

      expect { get customer_service_courses_url }.to raise_error(SecurityTransgression)
      expect { get customer_service_course_url(1) }.to raise_error(SecurityTransgression)
    end
  end
end
