require 'rails_helper'

RSpec.describe PeriodAccessPolicy, type: :access_policy do
  let(:course) { FactoryBot.create :course_profile_course }
  let(:period) { FactoryBot.create :course_membership_period, course: course }

  let(:anon)    do
    profile = User::Models::AnonymousProfile.instance
    strategy = User::Strategies::Direct::AnonymousUser.new(profile)
    User::User.new(strategy: strategy)
  end
  let(:user)    { FactoryBot.create(:user) }
  let(:student) { FactoryBot.create(:user) }
  let(:teacher) { FactoryBot.create(:user) }

  before do
    AddUserAsCourseTeacher[course: course, user: teacher]
    AddUserAsPeriodStudent[period: period, user: student]
  end

  # action, requestor are set in contexts
  subject(:allowed) { described_class.action_allowed?(action, requestor, period) }

  context 'anonymous users' do
    let(:requestor) { anon }

    [:read, :create, :update, :destroy, :restore].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should eq false }
      end
    end
  end

  context 'regular users' do
    let(:requestor) { user }

    [:read, :create, :update, :destroy, :restore].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should eq false }
      end
    end
  end

  context 'students' do
    let(:requestor) { student }

    context "read" do
      let(:action) { "read" }
      it { should eq true }
    end

    [:create, :update, :destroy, :restore].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should eq false }
      end
    end
  end

  context 'teachers' do
    let(:requestor) { teacher }

    [:read, :create, :update, :destroy, :restore].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should eq true }
      end
    end
  end
end
