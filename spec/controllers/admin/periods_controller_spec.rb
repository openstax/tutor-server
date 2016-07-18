require 'rails_helper'

RSpec.describe Admin::PeriodsController do
  let(:admin) { FactoryGirl.create(:user, :administrator) }

  let(:course) { Entity::Course.create! }
  let(:period) { CreatePeriod[course: course, name: '1st'] }

  before { controller.sign_in(admin) }

  context 'DELETE #destroy' do
    let(:student)       { FactoryGirl.create(:user) }
    let!(:student_role) { AddUserAsPeriodStudent.call(user: student, period: period) }

    it 'archives the period' do
      expect {
        delete :destroy, course_id: course.id, id: period.id
      }.to change { CourseMembership::Models::Period.count }.by(-1)
      expect(flash[:notice]).to eq 'Period "1st" archived.'
    end
  end

  context 'PUT #restore' do
    let(:student)       { FactoryGirl.create(:user) }
    let!(:student_role) { AddUserAsPeriodStudent.call(user: student, period: period) }

    it 'restores the period' do
      period.to_model.destroy!

      expect {
        put :restore, course_id: course.id, id: period.id
      }.to change { CourseMembership::Models::Period.count }.by(1)
      expect(flash[:notice]).to eq 'Period "1st" restored.'
    end
  end
end
