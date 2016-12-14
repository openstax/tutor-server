require 'rails_helper'

RSpec.describe TaskPlanAccessPolicy, type: :access_policy do

  before(:all) do
    @course = FactoryGirl.create :course_profile_course
    @period = FactoryGirl.create :course_membership_period, course: @course

    @task_plan = FactoryGirl.create(:tasks_task_plan, owner: @course)

    @clone_course = FactoryGirl.create :course_profile_course, cloned_from: @course
    @clone_period = FactoryGirl.create :course_membership_period, course: @clone_course

    @clone_task_plan = FactoryGirl.create(:tasks_task_plan, owner: @clone_course)

    @anonymous = User::User.anonymous
    @user = FactoryGirl.create(:user)
    @student = FactoryGirl.create(:user)
    @teacher = FactoryGirl.create(:user)
    @clone_student = FactoryGirl.create(:user)
    @clone_teacher = FactoryGirl.create(:user)

    @owner = FactoryGirl.create(:user)
    # NotYetImplemented, but we can kid of simulate it by creating a task_plan and then updating it
    @owned_task_plan = FactoryGirl.create(:tasks_task_plan)
    @owned_task_plan.update_attribute :owner, @owner.to_model

    AddUserAsPeriodStudent[user: @student, period: @period]
    AddUserAsCourseTeacher[user: @teacher, course: @course]
    AddUserAsPeriodStudent[user: @clone_student, period: @clone_period]
    AddUserAsCourseTeacher[user: @clone_teacher, course: @clone_course]
  end

  context 'original task plans' do
    context 'owned by the course' do
      # action, requestor are set in contexts
      subject(:allowed) { described_class.action_allowed?(action, requestor, @task_plan) }

      context 'anonymous users' do
        let(:requestor) { @anonymous }

        [:index, :read, :create, :update, :destroy].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq false }
          end
        end
      end

      context 'random users' do
        let(:requestor) { @user }

        context 'index' do
          let(:action) { :index }

          it { should eq true }
        end

        [:read, :create, :update, :destroy, :restore].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq false }
          end
        end
      end

      context 'students in the original course' do
        let(:requestor) { @student }

        context 'index' do
          let(:action) { :index }

          it { should eq true }
        end

        [:read, :create, :update, :destroy, :restore].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq false }
          end
        end
      end

      context 'students in the cloned course' do
        let(:requestor) { @clone_student }

        context 'index' do
          let(:action) { :index }

          it { should eq true }
        end

        [:read, :create, :update, :destroy, :restore].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq false }
          end
        end
      end

      context 'teachers in the original course' do
        let(:requestor) { @teacher }

        [:index, :read, :create, :update, :destroy, :restore].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq true }
          end
        end
      end

      context 'teachers in the cloned course' do
        let(:requestor) { @clone_teacher }

        [:index, :read].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq true }
          end
        end

        [:create, :update, :destroy, :restore].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq false }
          end
        end
      end
    end

    context 'owned by the user' do
      # action, requestor are set in contexts
      subject(:allowed) { described_class.action_allowed?(action, requestor, @owned_task_plan) }

      context 'anonymous users' do
        let(:requestor) { @anonymous }

        [:index, :read, :create, :update, :destroy].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq false }
          end
        end
      end

      context 'random users' do
        let(:requestor) { @user }

        context 'index' do
          let(:action) { :index }

          it { should eq true }
        end

        [:read, :create, :update, :destroy, :restore].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq false }
          end
        end
      end

      context 'task plan owners' do
        let(:requestor) { @owner }

        [:index, :read, :create, :update, :destroy, :restore].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq true }
          end
        end
      end
    end
  end

  context 'cloned task plans' do
    # action, requestor are set in contexts
    subject(:allowed) { described_class.action_allowed?(action, requestor, @clone_task_plan) }

    context 'anonymous users' do
      let(:requestor) { @anonymous }

      [:index, :read, :create, :update, :destroy].each do |test_action|
        context test_action.to_s do
          let(:action) { test_action }

          it { should eq false }
        end
      end
    end

    context 'random users' do
      let(:requestor) { @user }

      context 'index' do
        let(:action) { :index }

        it { should eq true }
      end

      [:read, :create, :update, :destroy, :restore].each do |test_action|
        context test_action.to_s do
          let(:action) { test_action }

          it { should eq false }
        end
      end
    end

    context 'students in the original course' do
      let(:requestor) { @student }

      context 'index' do
        let(:action) { :index }

        it { should eq true }
      end

      [:read, :create, :update, :destroy, :restore].each do |test_action|
        context test_action.to_s do
          let(:action) { test_action }

          it { should eq false }
        end
      end
    end

    context 'students in the cloned course' do
      let(:requestor) { @clone_student }

      context 'index' do
        let(:action) { :index }

        it { should eq true }
      end

      [:read, :create, :update, :destroy, :restore].each do |test_action|
        context test_action.to_s do
          let(:action) { test_action }

          it { should eq false }
        end
      end
    end

    context 'teachers in the original course' do
      let(:requestor) { @teacher }

      context 'index' do
        let(:action) { :index }

        it { should eq true }
      end

      [:read, :create, :update, :destroy, :restore].each do |test_action|
        context test_action.to_s do
          let(:action) { test_action }

          it { should eq false }
        end
      end
    end

    context 'teachers in the cloned course' do
      let(:requestor) { @clone_teacher }

      [:index, :read, :create, :update, :destroy, :restore].each do |test_action|
        context test_action.to_s do
          let(:action) { test_action }

          it { should eq true }
        end
      end
    end
  end

end
