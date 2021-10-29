require 'rails_helper'

RSpec.describe Admin::SalesforceController, type: :request do
  let(:admin)           { FactoryBot.create(:user_profile, :administrator) }
  let(:terms)           do
    CourseProfile::Models::Course.terms.values_at :spring, :summer, :fall, :winter
  end
  let!(:failed_courses) do
    [
      FactoryBot.create(:course_profile_course, term: terms.sample).tap do |course|
        FactoryBot.create :course_membership_teacher, course: course
      end,
      FactoryBot.create(:course_profile_course, term: terms.sample).tap do |course|
        FactoryBot.create :course_membership_student, course: course
      end,
      FactoryBot.create(:course_profile_course, term: terms.sample).tap do |course|
        FactoryBot.create :course_membership_teacher, course: course
        FactoryBot.create :course_membership_student, course: course
      end
    ]
  end
  let!(:empty_course)      { FactoryBot.create :course_profile_course, term: terms.sample }
  let!(:successful_course) do
    FactoryBot.create(:course_profile_course, term: terms.sample).tap do |course|
      FactoryBot.create(
        :course_membership_teacher, course: course
      ).role.profile.account.update_attribute :salesforce_contact_id, SecureRandom.uuid
      FactoryBot.create :course_membership_student, course: course
    end
  end

  before { sign_in! admin }

  context 'GET #failures' do
    it 'assigns failed_courses to @courses' do
      get failures_admin_salesforce_url

      expect(assigns[:courses]).to eq(failed_courses)
    end
  end
end
