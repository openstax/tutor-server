require 'rails_helper'

RSpec.describe CustomerService::StatsController, type: :controller do

  let(:customer_service) { FactoryBot.create(:user, :customer_service) }

  context "GET #courses" do
    let(:course)         { FactoryBot.create :course_profile_course }
    let(:periods)        do
      3.times.map { FactoryBot.create :course_membership_period, course: course }
    end

    let(:teacher_user)   { FactoryBot.create :user }
    let!(:teacher_role)  { AddUserAsCourseTeacher[course: course, user: teacher_user] }

    let!(:student_roles) do
      5.times.map do
        user = FactoryBot.create :user
        AddUserAsPeriodStudent[period: periods.sample, user: user]
      end
    end

    it "returns http success" do
      controller.sign_in customer_service

      get :courses
      expect(response).to have_http_status(:success)
    end
  end

  context "GET #excluded_exercises" do
    let(:course)              { FactoryBot.create :course_profile_course }

    let(:teacher_user)        { FactoryBot.create :user }
    let!(:teacher_role)       { AddUserAsCourseTeacher[course: course, user: teacher_user] }

    let!(:excluded_exercises) do
      5.times.map { FactoryBot.create :course_content_excluded_exercise, course: course }
    end

    it "returns http success" do
      controller.sign_in customer_service

      get :excluded_exercises
      expect(response).to have_http_status(:success)
    end
  end

  context "GET #concept_coach" do
    let(:tasks)     { 3.times.map { FactoryBot.create :tasks_task, task_type: :concept_coach } }
    let!(:cc_tasks) { tasks.map{ |task| FactoryBot.create :tasks_concept_coach_task, task: task } }

    it "returns http success" do
      controller.sign_in customer_service

      get :concept_coach
      expect(response).to have_http_status(:success)
    end
  end

end
