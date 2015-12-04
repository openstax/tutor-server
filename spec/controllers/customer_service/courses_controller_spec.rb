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
