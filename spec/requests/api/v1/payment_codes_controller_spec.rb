require 'rails_helper'
require 'vcr_helper'

RSpec.describe Api::V1::PaymentCodesController, type: :request, api: true, version: :v1 do
  let(:application)   { FactoryBot.create :doorkeeper_application }
  let(:course)        { FactoryBot.create :course_profile_course }
  let(:period)        { FactoryBot.create :course_membership_period, course: course }
  let(:student_user)  { FactoryBot.create :user_profile }
  let(:student_role)  { AddUserAsPeriodStudent[user: student_user, period: period] }
  let!(:student)      { student_role.student }

  let!(:unassigned_role) do
    FactoryBot.create :entity_role, profile: student_user, role_type: :unassigned
  end
  let!(:default_role)    do
    FactoryBot.create :entity_role, profile: student_user, role_type: :default
  end

  let(:student_token) do
    FactoryBot.create :doorkeeper_access_token, application: application,
                                                resource_owner_id: student_user.id
  end

  let(:user_2)        { FactoryBot.create(:user_profile) }
  let(:user_2_token)  { FactoryBot.create :doorkeeper_access_token, resource_owner_id: user_2.id }

  let(:unused_payment_code) { FactoryBot.create :payment_code }
  let(:used_payment_code)   { FactoryBot.create :payment_code, redeemed_at: 2.days.ago }

  context 'PUT #redeem' do
    it 'redeems an unused payment code' do
      api_put api_payment_code_redeem_url(unused_payment_code.code), student_token, params: { course_id: course.id }.to_json
      expect(response).to be_ok

      expect(unused_payment_code.reload.redeemed_at).not_to be nil
    end

    it 'rejects a used payment code' do
      expect {
        api_put api_payment_code_redeem_url(used_payment_code.code), student_token, params: { course_id: course.id }.to_json
      }.not_to change { used_payment_code.reload }
      expect(response).to have_http_status(422)
    end

    it 'returns 404 if the code is invalid' do
      api_put api_payment_code_redeem_url('invalid'), student_token, params: { course_id: course.id }.to_json
      expect(response).to have_http_status(404)
    end
  end
end
