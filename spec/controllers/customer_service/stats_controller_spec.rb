require 'rails_helper'

RSpec.describe CustomerService::StatsController, type: :controller do

  let!(:customer_service) { FactoryGirl.create(:user, :customer_service) }

  context "GET #courses" do
    let!(:course)        { Entity::Course.create! }
    let!(:periods)       do
      3.times.map { FactoryGirl.create :course_membership_period, course: course }
    end

    let!(:teacher_user)  { FactoryGirl.create :user }
    let!(:teacher_role)  { AddUserAsCourseTeacher[course: course, user: teacher_user] }

    let!(:student_roles) do
      5.times.map do
        user = FactoryGirl.create :user
        AddUserAsPeriodStudent[period: periods.sample, user: user]
      end
    end

    it "returns http success" do
      controller.sign_in customer_service

      get :courses
      expect(response).to have_http_status(:success)
    end
  end

end
