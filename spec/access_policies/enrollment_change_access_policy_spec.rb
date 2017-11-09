require 'rails_helper'

RSpec.describe EnrollmentChangeAccessPolicy, type: :access_policy do
  let(:course)            { FactoryBot.create :course_profile_course }
  let(:period)            { FactoryBot.create :course_membership_period, course: course }

  let(:user)              do
    profile = FactoryBot.create(:user_profile)
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  end
  let(:another_user)      do
    profile = FactoryBot.create(:user_profile)
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  end

  let(:enrollment_change) do
    CourseMembership::CreateEnrollmentChange[
      user: user, enrollment_code: period.enrollment_code
    ]
  end

  # action, requestor are set in contexts
  subject(:allowed)       do
    described_class.action_allowed?(
      action, requestor, action == :create ? CourseMembership::Models::EnrollmentChange : \
                                             enrollment_change)
  end

  context 'anonymous users' do
    let(:requestor) { User::User.anonymous }

    [:create, :approve].each do |test_action|
      context test_action.to_s do
        let(:action) { test_action }
        it { should eq false }
      end
    end
  end

  context 'the user in the enrollment change' do
    let(:requestor) { user }

    [:create, :approve].each do |test_action|
      context test_action.to_s do
        let(:action) { test_action }
        it { should eq true }
      end
    end
  end

  context 'another user' do
    let(:requestor) { another_user }

    context 'create' do
      let(:action) { :create }
      it { should eq true }
    end

    context 'approve' do
      let(:action) { :approve }
      it { should eq false }
    end
  end
end
