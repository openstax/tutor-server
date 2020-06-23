require 'rails_helper'

RSpec.describe Admin::PeriodsController, type: :request do
  let(:admin)  { FactoryBot.create(:user_profile, :administrator) }

  let(:course) { FactoryBot.create :course_profile_course }
  let(:period) { FactoryBot.create :course_membership_period, course: course }

  before       { sign_in! admin }

  context 'DELETE #destroy' do
    let(:student)       { FactoryBot.create(:user_profile) }
    let!(:student_role) { AddUserAsPeriodStudent.call(user: student, period: period) }

    it 'archives the period' do
      expect do
        delete admin_period_url(period.id)
      end.to change { period.reload.archived? }.from(false).to(true)
      expect(flash[:notice]).to eq 'Period "1st" archived.'
    end
  end

  context 'PUT #restore' do
    let(:student)       { FactoryBot.create(:user_profile) }
    let!(:student_role) { AddUserAsPeriodStudent.call(user: student, period: period) }

    it 'restores the period' do
      period.destroy!

      expect do
        put restore_admin_period_url(period.id)
      end.to change { period.reload.archived? }.from(true).to(false)
      expect(flash[:notice]).to eq 'Period "1st" unarchived.'
    end
  end
end
