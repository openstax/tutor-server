require 'rails_helper'

RSpec.describe Admin::SalesforceController, type: :request do
  let(:admin)           { FactoryBot.create(:user_profile, :administrator) }
  let(:terms)           do
    CourseProfile::Models::Course.terms.values_at :spring, :summer, :fall, :winter
  end
  let!(:failed_courses) do
    [
      FactoryBot.create(:course_profile_course, term: terms.sample),
      FactoryBot.create(:course_profile_course, term: terms.sample).tap do |course|
        FactoryBot.create :course_membership_teacher, course: course
      end,
      FactoryBot.create(:course_profile_course, term: terms.sample).tap do |course|
        period = FactoryBot.create :course_membership_period, course: course
        FactoryBot.create :course_membership_student, period: period
      end,
      FactoryBot.create(:course_profile_course, term: terms.sample).tap do |course|
        FactoryBot.create :course_membership_teacher, course: course
        period = FactoryBot.create :course_membership_period, course: course
        FactoryBot.create :course_membership_student, period: period
      end
    ]
  end
  let!(:successful_course) do
    FactoryBot.create(:course_profile_course, term: terms.sample).tap do |course|
      FactoryBot.create(
        :course_membership_teacher, course: course
      ).role.profile.account.update_attribute :salesforce_contact_id, SecureRandom.uuid
      period = FactoryBot.create :course_membership_period, course: course
      FactoryBot.create :course_membership_student, period: period
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
