require 'rails_helper'

RSpec.describe Admin::PeriodsController do
  let(:admin)  { FactoryBot.create(:user, :administrator) }

  let(:course) { FactoryBot.create :course_profile_course }
  let(:period) { FactoryBot.create :course_membership_period, course: course }

  before       { controller.sign_in(admin) }

  context 'DELETE #destroy' do
    let(:student)       { FactoryBot.create(:user) }
    let!(:student_role) { AddUserAsPeriodStudent.call(user: student, period: period) }

    it 'archives the period' do
      expect {
        delete :destroy, course_id: course.id, id: period.id
      }.to change { period.reload.archived? }.from(false).to(true)
      expect(flash[:notice]).to eq 'Period "1st" archived.'
    end
  end

  context 'PUT #restore' do
    let(:student)       { FactoryBot.create(:user) }
    let!(:student_role) { AddUserAsPeriodStudent.call(user: student, period: period) }

    it 'restores the period' do
      period.to_model.destroy!

      expect {
        put :restore, course_id: course.id, id: period.id
      }.to change { period.reload.archived? }.from(true).to(false)
      expect(flash[:notice]).to eq 'Period "1st" unarchived.'
    end
  end
end
