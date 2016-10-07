require 'rails_helper'

RSpec.describe EnrollmentChangeAccessPolicy, type: :access_policy do
  let(:course)            { FactoryGirl.create :entity_course }
  let(:period)            { FactoryGirl.create :course_membership_period, course: course }

  let(:user)              {
    profile = FactoryGirl.create(:user_profile)
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }
  let(:another_user)      {
    profile = FactoryGirl.create(:user_profile)
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }

  let(:enrollment_change) {
    CourseMembership::CreateEnrollmentChange[user: user, period: period]
  }

  # action, requestor are set in contexts
  subject(:allowed)        {
    described_class.action_allowed?(
      action, requestor, action == :create ? CourseMembership::Models::EnrollmentChange : \
                                             enrollment_change)
  }

  context 'anonymous users' do
    let(:requestor) { User::User.anonymous }

    [:create, :approve].each do |test_action|
      context test_action.to_s do
        let(:action) { test_action }
        it { should be false }
      end
    end
  end

  context 'the user in the enrollment change' do
    let(:requestor) { user }

    [:create, :approve].each do |test_action|
      context test_action.to_s do
        let(:action) { test_action }
        it { should be true }
      end
    end
  end

  context 'another user' do
    let(:requestor) { another_user }

    context 'create' do
      let(:action) { :create }
      it { should be true }
    end

    context 'approve' do
      let(:action) { :approve }
      it { should be false }
    end
  end
end
