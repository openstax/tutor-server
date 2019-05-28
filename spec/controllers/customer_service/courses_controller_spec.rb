require 'rails_helper'

RSpec.describe CustomerService::CoursesController, type: :controller do
  let(:customer_service) { FactoryBot.create(:user, :customer_service) }

  before                 { controller.sign_in(customer_service) }

  context 'GET #index' do
    it 'assigns all CollectCourseInfo output to @course_infos' do
      FactoryBot.create :course_profile_course, name: 'Hello World'

      get :index

      expect(assigns[:course_infos].count).to eq(1)
      expect(assigns[:course_infos].first.name).to eq('Hello World')
    end

    it 'passes the query param to SearchCourses along with order_by params' do
      expect(SearchCourses).to receive(:call).with(query: 'test', order_by: 'name').once.and_call_original
      get :index, params: { query: 'test', order_by: 'name' }
    end

    context "pagination" do
      context "when the are any results" do
        before do
          4.times {FactoryBot.create(:course_profile_course, name: "Algebra #{rand(1000)}")}
          expect(CourseProfile::Models::Course.count).to eq(4)
        end

        it "paginates the results" do
          get :index, params: { page: 1, per_page: 2 }
          expect(assigns[:course_infos].length).to eq(2)
        end

        it "can access other pages" do
          get :index, params: { page: 2, per_page: 2 }
          expect(assigns[:course_infos].length).to eq(2)
        end
      end

      context "when there are no results" do
        it "doesn't blow up" do
          expect(CourseProfile::Models::Course.count).to eq(0)

          get :index, params: { page: 1 }
          expect(response).to have_http_status :ok
        end
      end
    end
  end

  context 'GET #show' do
    it 'assigns extra course info' do
      course = FactoryBot.create :course_profile_course, :without_ecosystem, name: 'Hello World'

      get :show, params: { id: course.id }

      expect(assigns[:course].id).to eq course.id
      expect(Set.new assigns[:periods]).to eq Set.new course.periods
      expect(Set.new assigns[:teachers]).to eq Set.new course.teachers
      expect(Set.new assigns[:ecosystems]).to eq Set.new Content::ListEcosystems[]
      expect(assigns[:course_ecosystem]).to be_nil
    end
  end

  context 'disallowing baddies' do
    it '#GET disallows unauthenticated visitors' do
      allow(controller).to receive(:current_account) { nil }
      allow(controller).to receive(:current_user) { nil }

      get :index
      expect(response).not_to be_successful
    end

    it '#PUT disallows unauthenticated visitors' do
      allow(controller).to receive(:current_account) { nil }
      allow(controller).to receive(:current_user) { nil }

      get :show, params: { id: 1 }
      expect(response).not_to be_successful
    end

    it 'disallows non-customer-service authenticated visitors' do
      controller.sign_in(FactoryBot.create(:user))

      expect { get :index }.to raise_error(SecurityTransgression)
      expect { get :show, params: { id: 1 } }.to raise_error(SecurityTransgression)
    end
  end
end
