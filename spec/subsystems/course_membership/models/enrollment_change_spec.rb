require 'rails_helper'

RSpec.describe CourseMembership::Models::EnrollmentChange, type: :model, speed: :medium do
  let(:course_1)  { FactoryBot.create :course_profile_course }
  let(:course_2)  { FactoryBot.create :course_profile_course }

  let(:period_1)  { FactoryBot.create :course_membership_period, course: course_1 }
  let(:period_2)  { FactoryBot.create :course_membership_period, course: course_1 }
  let(:period_3)  { FactoryBot.create :course_membership_period, course: course_2 }

  let(:book)      { FactoryBot.create :content_book }

  let(:ecosystem) { Content::Ecosystem.new(strategy: book.ecosystem.wrap) }

  let(:user)                  do
    profile = FactoryBot.create :user_profile
    strategy = ::User::Strategies::Direct::User.new(profile)
    ::User::User.new(strategy: strategy)
  end

  let!(:role)                 do
    AddUserAsPeriodStudent[user: user, period: period_1]
  end

  let(:enrollment)            { role.student.latest_enrollment }

  before                      { AddEcosystemToCourse[course: course_1, ecosystem: ecosystem] }

  subject(:enrollment_change) do
    CourseMembership::CreateEnrollmentChange[
      user: user, enrollment_code: period_2.enrollment_code
    ].to_model
  end

  it { is_expected.to belong_to(:profile) }
  it { is_expected.to belong_to(:enrollment).optional }
  it { is_expected.to belong_to(:period) }

  it 'knows the target period' do
    expect(enrollment_change.to_period).to eq period_2
  end

  it 'can be approved by the enrollee' do
    enrollment_change.approve_by(user)
    expect(enrollment_change.enrollee_approved_at).to be_present
  end

  it 'requires the target course to not have yet ended' do
    current_time = Time.current
    expect(enrollment_change).to be_valid

    course_1.starts_at = current_time.last_month
    course_1.ends_at = current_time.yesterday
    course_1.save!

    expect(enrollment_change.reload).not_to be_valid
    expect(enrollment_change.errors.first).to(
      eq [:period, 'belongs to a course that has already ended']
    )
  end

  context 'for an existing enrollment' do
    it 'knows the previous period' do
      expect(enrollment_change.from_period).to eq period_1
    end

    it 'requires the profile and the enrollment\'s student to refer to the same user' do
      expect(enrollment_change).to be_valid

      enrollment_change.profile = FactoryBot.create :user_profile
      expect(enrollment_change).not_to be_valid
      expect(enrollment_change.errors[:base]).to include(
        'the given user does not match the given enrollment'
      )
    end

    it 'requires the period and the enrollment\'s period to be different' do
      course_1.update_attribute :is_concept_coach, true
      course_2.update_attribute :is_concept_coach, true
      expect(enrollment_change).to be_valid

      enrollment_change.period = enrollment_change.enrollment.period
      expect(enrollment_change).not_to be_valid
      expect(enrollment_change.errors[:base]).to include(
        'the given user is already enrolled in the given period'
      )
    end

    it 'requires the period and the enrollment\'s period to be in the same course' do
      expect(enrollment_change).to be_valid

      enrollment_change.period = period_3
      expect(enrollment_change).not_to be_valid
      expect(enrollment_change.errors[:base]).to include(
        'the given periods must belong to the same course'
      )

      enrollment_change.period = period_2

      expect(enrollment_change).to be_valid
    end
  end

  context 'for a new enrollment' do
    before(:each) { enrollment_change.enrollment = nil }

    it 'has no previous period' do
      expect(enrollment_change.from_period).to be_nil
    end
  end
end
