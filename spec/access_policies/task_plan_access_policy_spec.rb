require 'rails_helper'

RSpec.describe TaskPlanAccessPolicy, type: :access_policy do
  let(:task_plan)     { FactoryGirl.create(:tasks_task_plan) }

  let(:course)        { FactoryGirl.create :course_profile_course }
  let(:teacher)       { FactoryGirl.create(:user) }
  let(:not_teaching)  { FactoryGirl.create(:user) }
  let(:owner)         { FactoryGirl.create(:user) }
  let(:non_owner)     { FactoryGirl.create(:user) }

  before do
    AddUserAsCourseTeacher[course: course, user: teacher]
  end

  # action, requestor are set in contexts
  subject(:allowed) { described_class.action_allowed?(action, requestor, task_plan) }

  context 'anonymous users' do
    let(:requestor) { User::User.anonymous }

    [:index, :read, :create, :update, :destroy].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should eq false }
      end
    end
  end

  context 'course teachers' do
    let(:requestor) { teacher }

    before do
      task_plan.owner = course
      task_plan.save!
    end

    [:read, :create, :update, :destroy, :restore].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should eq true }
      end
    end
  end

  context 'not course teachers' do
    let(:requestor) { not_teaching }

    before do
      task_plan.owner = course
      task_plan.save!
    end

    [:read, :create, :update, :destroy, :restore].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should eq false }
      end
    end
  end

  context 'human owners' do
    let(:requestor) { owner }

    before do
      task_plan.owner = owner.to_model
      task_plan.save!
    end

    [:read, :create, :update, :destroy, :restore].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should eq true }
      end
    end
  end

  context 'non-owners' do
    let(:requestor) { non_owner }

    [:read, :create, :update, :destroy, :restore].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should eq false }
      end
    end
  end
end
