require 'rails_helper'

RSpec.describe CourseMembership::Models::EnrollmentChange, type: :model do
  let!(:period_1)             { CreatePeriod.call(course: Entity::Course.create!).period }
  let!(:period_2)             { CreatePeriod.call(course: period_1.course).period }

  let!(:user)                 do
    profile = FactoryGirl.create :user_profile
    strategy = ::User::Strategies::Direct::User.new(profile)
    ::User::User.new(strategy: strategy)
  end

  let!(:role)                 do
    AddUserAsPeriodStudent.call(user: user, period: period_1)
  end

  let!(:enrollment)           { role.student.latest_enrollment }

  subject(:enrollment_change) {
    CourseMembership::CreateEnrollmentChange.call(user: user, period: period_2)
                                            .enrollment_change.to_model
  }

  it { is_expected.to belong_to(:profile) }
  it { is_expected.to belong_to(:enrollment) }
  it { is_expected.to belong_to(:period) }

  it { is_expected.to validate_presence_of(:profile) }
  it { is_expected.to validate_presence_of(:period) }

  it { is_expected.to validate_uniqueness_of(:enrollment).allow_nil }

  it 'knows the target period' do
    expect(enrollment_change.to_period).to eq period_2.to_model
  end

  it 'can be approved by the enrollee' do
    enrollment_change.approve_by(user)
    expect(enrollment_change.enrollee_approved_at).to be_present
  end

  context 'for an existing enrollment' do
    it 'knows the previous period' do
      expect(enrollment_change.from_period).to eq period_1.to_model
    end

    it 'requires the profile and the enrollment\'s student to refer to the same user' do
      expect(enrollment_change).to be_valid

      enrollment_change.profile = FactoryGirl.create :user_profile
      expect(enrollment_change).not_to be_valid
      expect(enrollment_change.errors[:base]).to include(
        'the given user does not match the given enrollment'
      )
    end

    it 'requires the period and the enrollment\'s period to be different' do
      expect(enrollment_change).to be_valid

      enrollment_change.profile = FactoryGirl.create :user_profile
      expect(enrollment_change).not_to be_valid
      expect(enrollment_change.errors[:base]).to include(
        'the given user does not match the given enrollment'
      )
    end
  end

  context 'for a new enrollment' do
    before(:each) { enrollment_change.enrollment = nil }
    
    it 'has no previous period' do
      expect(enrollment_change.from_period).to be_nil
    end
  end
end
