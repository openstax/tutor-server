require 'rails_helper'

RSpec.describe PurchasesController, type: :controller do
  let(:course) { FactoryGirl.create :course_profile_course }
  let(:period) { FactoryGirl.create :course_membership_period, course: course }

  let(:student_1_user) { FactoryGirl.create(:user) }
  let(:student_1) { AddUserAsPeriodStudent[period: period, user: student_1_user].student }

  let(:student_2_user) { FactoryGirl.create(:user) }
  let(:student_2) { AddUserAsPeriodStudent[period: period, user: student_2_user].student }

  it 'redirects users to sign in before access' do
    get :show, id: 'whatever'
    expect(response).to redirect_to(%r{/accounts/login})
  end

  context 'student purchases' do
    before(:each) { controller.sign_in(student_1_user) }

    it 'gives not found error for bad ID' do
      expect{
        get :show, id: 'badnesshere'
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'gives forbidden error if user does not own that ID' do
      expect{
        get :show, id: student_2.uuid
      }.to raise_error(SecurityTransgression)
    end

    it 'redirects on the happy path' do
      get :show, id: student_1.uuid
      expect(response).to redirect_to(%r{/course/#{student_1.course.id}})
    end
  end
end
