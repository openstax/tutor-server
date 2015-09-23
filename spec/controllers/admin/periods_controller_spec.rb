require 'rails_helper'

RSpec.describe Admin::PeriodsController do
  let!(:admin) {
    profile = FactoryGirl.create(:user_profile, :administrator)
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }

  let!(:course) { Entity::Course.create }
  let!(:period) { CreatePeriod[course: course, name: '1st'] }

  before { controller.sign_in(admin) }

  describe 'DELETE #destroy' do
    context 'when there are no students' do
      it 'deletes a period' do
        expect {
          delete :destroy, course_id: course.id, id: period.id
        }.to change { CourseMembership::Models::Period.count }.by(-1)
        expect(flash[:notice]).to eq 'Period "1st" deleted.'
      end
    end

    context 'when there are students' do
      let!(:student) {
        profile = FactoryGirl.create(:user_profile)
        strategy = User::Strategies::Direct::User.new(profile)
        User::User.new(strategy: strategy)
      }
      let!(:add_student) { AddUserAsPeriodStudent.call(user: student, period: period) }

      it 'displays an error message' do
        expect {
          delete :destroy, course_id: course.id, id: period.id
        }.not_to change { CourseMembership::Models::Period.count }
        expect(flash[:error]).to eq [
          'Students must be moved to another period before this period can be deleted']
      end
    end
  end
end
