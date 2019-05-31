require 'rails_helper'

RSpec.describe Research::CohortsController, type: :controller do
  let(:cohort) { FactoryBot.create :research_cohort }

  let(:researcher) { FactoryBot.create :user, :researcher }

  before { controller.sign_in(researcher) }

  context 'GET #members' do
    render_views

    it 'lists members' do
      student = FactoryBot.create :course_membership_student
      student.role.update_attributes profile: FactoryBot.create(:user_profile)
      Research::CohortMembershipManager.new(cohort.study).add_student_to_a_cohort(student)
      get :members, params: { cohort_id: cohort.id }
      expect(response.body).to include student.role.profile.username
    end
  end
end
