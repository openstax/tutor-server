require 'rails_helper'

RSpec.describe CustomerService::CoursesController, type: :controller do
  let(:customer_service) {
    profile = FactoryGirl.create(:user_profile, :customer_service)
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }

  before { controller.sign_in(customer_service) }

  describe 'GET #index' do
    it 'assigns all CollectCourseInfo output to @courses' do
      CreateCourse[name: 'Hello World']
      get :index

      expect(assigns[:courses].count).to eq(1)
      expect(assigns[:courses].first.name).to eq('Hello World')
    end
  end

  describe 'GET #show' do
    it 'assigns extra course info' do
      course = CreateCourse[name: 'Hello World']
      get :show, id: course.id

      expect(assigns[:course].course_id).to eq course.id
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
      profile = FactoryGirl.create(:user_profile)
      strategy = User::Strategies::Direct::User.new(profile)
      non_customer_service = User::User.new(strategy: strategy)
      controller.sign_in(non_customer_service)

      expect { get :index }.to raise_error(SecurityTransgression)
      expect { get :show, id: 1 }.to raise_error(SecurityTransgression)
    end
  end
end
