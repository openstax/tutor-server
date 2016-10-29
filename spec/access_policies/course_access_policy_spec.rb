require 'rails_helper'

RSpec.describe CourseAccessPolicy, type: :access_policy do
  let(:course)           { FactoryGirl.create :course_profile_course }
  let(:period)           { FactoryGirl.create :course_membership_period, course: course }

  let(:student)          { FactoryGirl.create(:user) }
  let(:teacher)          { FactoryGirl.create(:user) }
  let(:verified_faculty) { FactoryGirl.create(:user) }

  before do
    AddUserAsCourseTeacher[course: course, user: teacher]
    AddUserAsPeriodStudent[period: period, user: student]
    teacher.account.update_attribute :faculty_status, :confirmed_faculty
    verified_faculty.account.update_attribute :faculty_status, :confirmed_faculty
  end

  # action, requestor are set in contexts
  subject(:allowed) { described_class.action_allowed?(action, requestor, course) }

  context 'anonymous user' do
    let(:requestor) {
      profile = User::Models::AnonymousProfile.instance
      strategy = User::Strategies::Direct::AnonymousUser.new(profile)
      User::User.new(strategy: strategy)
    }

    [:index, :read, :task_plans, :export, :roster, :add_period,
     :update, :stats, :exercises, :clone, :create].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be false }
      end
    end
  end

  context 'regular user' do
    let(:requestor) { FactoryGirl.create(:user) }

    context ":index" do
      let(:action) { :index }
      it { should be true }
    end

    [:read, :task_plans, :export, :roster, :add_period,
     :update, :stats, :exercises, :clone, :create].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be false }
      end
    end
  end

  context 'student' do
    let(:requestor) { student }

    [:index, :read, :task_plans].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be true }
      end
    end

    [:export, :roster, :add_period, :update,
     :stats, :exercises, :clone, :create].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be false }
      end
    end
  end

  context 'verified faculty teacher' do
    let(:requestor) { teacher }

    [:index, :create, :read, :task_plans, :export, :roster,
     :add_period, :update, :stats, :exercises, :clone].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be true }
      end
    end
  end

  context 'verified faculty without a course' do
    let(:requestor) { verified_faculty }

    [:index, :create].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be true }
      end
    end

    [:read, :task_plans, :export, :roster,
     :add_period, :update, :stats, :exercises, :clone].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be false }
      end
    end
  end
end
