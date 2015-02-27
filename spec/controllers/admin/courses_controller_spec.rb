require 'rails_helper'

RSpec.describe Admin::CoursesController do
  let(:admin) { FactoryGirl.create(:user, :administrator) }

  before { controller.sign_in(admin) }

  describe 'GET #index' do
    it 'assigns all Entity::Courses to @courses' do
      Domain::CreateCourse.call
      get :index
      expect(assigns[:courses]).to eq([Entity::Course.last])
    end
  end

  describe 'POST #create' do
    it 'creates a blank course' do
      expect {
        post :create
      }.to change { Entity::Course.count }.by(1)
    end

    it 'sets a flash notice' do
      post :create
      expect(flash[:notice]).to eq('The course has been created.')
    end

    it 'redirects to /admin/courses' do
      post :create
      expect(response).to redirect_to(admin_courses_path)
    end
  end
end
