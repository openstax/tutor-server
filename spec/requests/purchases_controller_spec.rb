require 'rails_helper'

RSpec.describe PurchasesController, type: :request do
  let(:course) { FactoryBot.create :course_profile_course }
  let(:period) { FactoryBot.create :course_membership_period, course: course }

  let(:student_1_user) { FactoryBot.create(:user_profile) }
  let(:student_1) { AddUserAsPeriodStudent[period: period, user: student_1_user].student }

  let(:student_2_user) { FactoryBot.create(:user_profile) }
  let(:student_2) { AddUserAsPeriodStudent[period: period, user: student_2_user].student }

  it 'redirects users to sign in before access' do
    get purchase_url('whatever')
    expect(response).to redirect_to(controller.send(:openstax_accounts_login_path))
  end

  context 'student purchases' do
    before(:each) { sign_in! student_1_user }

    it 'gives not found error for bad ID' do
      expect do
        get purchase_url('badnesshere')
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'gives forbidden error if user does not own that ID' do
      expect do
        get purchase_url(student_2.uuid)
      end.to raise_error(SecurityTransgression)
    end

    it 'redirects on the happy path' do
      get purchase_url(student_1.uuid)
      expect(response).to redirect_to(course_dashboard_path(student_1.course.id))
    end
  end
end
