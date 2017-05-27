require 'rails_helper'

RSpec.describe 'Api::V1::ApiController#error_if_student_and_needs_to_pay', type: :controller, api: true, version: :v1 do

  controller(Api::V1::ApiController) do
    skip_filter *(_process_action_callbacks.map(&:filter))
    before_filter :set_course_or_student
    before_filter :error_if_student_and_needs_to_pay

    def index
      head :ok
    end

    def set_course_or_student
      @course = CourseProfile::Models::Course.find(params[:course_id]) if params[:course_id]
      @student = CourseMembership::Models::Student.find(params[:student_id]) if params[:student_id]
    end
  end



  let(:application)       { FactoryGirl.create :doorkeeper_application }
  let(:course)            { FactoryGirl.create :course_profile_course }
  let(:period)            { FactoryGirl.create :course_membership_period, course: course }

  let(:student_user)      { FactoryGirl.create(:user) }
  let(:student_role)      { AddUserAsPeriodStudent[user: student_user, period: period] }
  let!(:student)          { student_role.student }
  let(:student_token)     { FactoryGirl.create :doorkeeper_access_token,
                                               application: application,
                                               resource_owner_id: student_user.id }


  let(:non_student_user)      { FactoryGirl.create(:user) }
  let(:non_student_token)     { FactoryGirl.create :doorkeeper_access_token,
                                                   application: application,
                                                   resource_owner_id: non_student_user.id }

  context 'error_if_student_and_needs_to_pay' do
    before(:each) { allow(Settings::Payments).to receive(:payments_enabled) { true } }

    context 'when the user is a student in the course' do
      it 'returns true when course is free' do
        student.update_attribute(:payment_due_at, 40.years.ago)
        api_get :index, student_token, parameters: { course_id: course.id }
        expect(response).to have_http_status(:success)
      end

      context 'when the course costs' do
        before(:each) { course.update_attributes(does_cost: true) }

        it 'return true when uncomped/unpaid but still in grace period' do
          student.update_attributes(payment_due_at: 3.days.from_now)
          api_get :index, student_token, parameters: { course_id: course.id }
          expect(response).to have_http_status(:success)
        end

        # TODO spec boundaries of grace period time

        it 'errors when unpaid/uncomped and the grace period has passed' do
          student.update_attributes(payment_due_at: 1.day.ago)
          api_get :index, student_token, parameters: { course_id: course.id }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns true when paid' do
          student.update_attributes(payment_due_at: 3.days.ago, is_paid: true)
          api_get :index, student_token, parameters: { course_id: course.id }
          expect(response).to have_http_status(:success)
        end

        it 'returns true when comped' do
          student.update_attributes(payment_due_at: 3.days.ago, is_comped: true)
          api_get :index, student_token, parameters: { course_id: course.id }
          expect(response).to have_http_status(:success)
        end
      end
    end

    context 'when the user is not a student in the course' do
      it 'returns true' do
        api_get :index, non_student_token, parameters: { course_id: course.id }
        expect(response).to have_http_status(:success)
      end
    end
  end

  it 'still works when just student specified' do
    allow(Settings::Payments).to receive(:payments_enabled) { true }
    course.update_attributes(does_cost: true)
    student.update_attributes(payment_due_at: 3.days.ago, is_paid: true)
    api_get :index, student_token, parameters: { student_id: student.id }
  end

  it 'return true when global payments_enabled is false' do
    allow(Settings::Payments).to receive(:payments_enabled) { false }
    course.update_attributes(does_cost: true)
    student.update_attributes(payment_due_at: 3.days.ago, is_paid: false)
    api_get :index, student_token, parameters: { student_id: student.id }
    expect(response).to have_http_status(:success)
  end

end
