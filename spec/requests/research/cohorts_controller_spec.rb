require 'rails_helper'

RSpec.describe Research::CohortsController, type: :request do
  let(:cohort) { FactoryBot.create :research_cohort }

  let(:researcher) { FactoryBot.create :user_profile, :researcher }

  before { sign_in! researcher }

  context 'GET #members' do
    it 'lists members' do
      student = FactoryBot.create :course_membership_student
      student.role.update_attributes profile: FactoryBot.create(:user_profile)
      Research::CohortMembershipManager.new(cohort.study).add_student_to_a_cohort(student)
      get research_cohort_members_url(cohort.id)
      expect(response.body).to include student.role.profile.username
    end
  end
end
