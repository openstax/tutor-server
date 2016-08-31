require 'rails_helper'

RSpec.describe CustomerService::CoursesController, type: :controller do
  let(:customer_service) { FactoryGirl.create(:user, :customer_service) }

  before { controller.sign_in(customer_service) }

  describe 'GET #index' do
    it 'assigns all CollectCourseInfo output to @course_infos' do
      CreateCourse[name: 'Hello World']
      get :index

      expect(assigns[:course_infos].count).to eq(1)
      expect(assigns[:course_infos].first.name).to eq('Hello World')
    end

    it 'passes the query param to SearchCourses along with order_by params' do
      expect(SearchCourses).to receive(:call).with(query: 'test', order_by: 'name').once.and_call_original
      get :index, query: 'test', order_by: 'name'
    end

    context "pagination" do
      context "when the are any results" do
        it "paginates the results" do
          4.times {FactoryGirl.create(:course_profile_profile, name: "Algebra #{rand(1000)}")}
          expect(CourseProfile::Models::Profile.count).to eq(4)

          get :index, page: 1, per_page: 2
          expect(assigns[:course_infos].length).to eq(2)

          get :index, page: 2, per_page: 2
          expect(assigns[:course_infos].length).to eq(2)
        end
      end

      context "when there are no results" do
        it "doesn't blow up" do
          expect(CourseProfile::Models::Profile.count).to eq(0)

          get :index, page: 1
          expect(response).to have_http_status :ok
        end
      end
    end
  end

  describe 'GET #show' do
    it 'assigns extra course info' do
      course = CreateCourse[name: 'Hello World']
      get :show, id: course.id

      expect(assigns[:profile].entity_course_id).to eq course.id
      expect(Set.new assigns[:periods]).to eq Set.new course.periods
      expect(Set.new assigns[:teachers]).to eq Set.new course.teachers
      expect(Set.new assigns[:ecosystems]).to eq Set.new Content::ListEcosystems[]
      expect(assigns[:course_ecosystem]).to be_nil
    end
  end

  context 'disallowing baddies' do
    it 'disallows unauthenticated visitors' do
      allow(controller).to receive(:current_account) { nil }
      allow(controller).to receive(:current_user) { nil }

      get :index
      expect(response).not_to be_success

      get :show, id: 1
      expect(response).not_to be_success
    end

    it 'disallows non-customer-service authenticated visitors' do
      controller.sign_in(FactoryGirl.create(:user))

      expect { get :index }.to raise_error(SecurityTransgression)
      expect { get :show, id: 1 }.to raise_error(SecurityTransgression)
    end
  end
end
