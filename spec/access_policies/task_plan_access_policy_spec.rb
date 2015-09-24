require 'rails_helper'

RSpec.describe TaskPlanAccessPolicy, type: :access_policy do
  let!(:task_plan)     { FactoryGirl.create(:tasks_task_plan) }

  let!(:course)        { CreateCourse[name: 'Biology 201'] }
  let!(:teacher)       {
    profile = FactoryGirl.create(:user_profile)
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }
  let!(:not_teaching)  {
    profile = FactoryGirl.create(:user_profile)
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }
  let!(:owner_profile) {
    FactoryGirl.create(:user_profile)
  }
  let!(:owner)         {
    strategy = User::Strategies::Direct::User.new(owner_profile)
    User::User.new(strategy: strategy)
  }
  let!(:non_owner)     {
    profile = FactoryGirl.create(:user_profile)
    strategy = User::Strategies::Direct::User.new(profile)
    User::User.new(strategy: strategy)
  }

  before do
    AddUserAsCourseTeacher[course: course, user: teacher]
  end

  # action, requestor are set in contexts
  subject(:allowed) { described_class.action_allowed?(action, requestor, task_plan) }

  context 'anonymous users' do
    let(:requestor) { User::User.anonymous }

    [:read, :create, :update, :destroy].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be false }
      end
    end
  end

  context 'course teachers' do
    let(:requestor) { teacher }

    before do
      task_plan.owner = course
      task_plan.save!
    end

    [:read, :create, :update, :destroy].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be true }
      end
    end
  end

  context 'not course teachers' do
    let(:requestor) { not_teaching }

    before do
      task_plan.owner = course
      task_plan.save!
    end

    [:read, :create, :update, :destroy].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be false }
      end
    end
  end

  context 'human owners' do
    let(:requestor) { owner }

    before do
      task_plan.owner = owner_profile
      task_plan.save!
    end

    [:read, :create, :update, :destroy].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be true }
      end
    end
  end

  context 'non-owners' do
    let(:requestor) { non_owner }

    [:read, :create, :update, :destroy].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be false }
      end
    end
  end
end
