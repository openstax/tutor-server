require 'rails_helper'

RSpec.describe CourseAccessPolicy, type: :access_policy do
  before(:all) do
    @course = FactoryBot.create :course_profile_course
    @period = FactoryBot.create :course_membership_period, course: @course

    @clone_course = FactoryBot.create :course_profile_course, cloned_from: @course
    @clone_period = FactoryBot.create :course_membership_period, course: @clone_course

    @copied_course = FactoryBot.create :course_profile_course,
                                       environment: FactoryBot.create(:environment)
    @copied_period = FactoryBot.create :course_membership_period, course: @copied_course

    @anonymous = User::Models::Profile.anonymous
    @user = FactoryBot.create :user_profile
    @student = FactoryBot.create :user_profile
    @faculty = FactoryBot.create :user_profile
    @new_faculty = FactoryBot.create :user_profile
    @clone_student = FactoryBot.create :user_profile
    @clone_faculty = FactoryBot.create :user_profile
    @copied_student = FactoryBot.create :user_profile
    @copied_faculty = FactoryBot.create :user_profile

    AddUserAsPeriodStudent[period: @period, user: @student]
    AddUserAsCourseTeacher[course: @course, user: @faculty]

    AddUserAsPeriodStudent[period: @clone_period, user: @clone_student]
    AddUserAsCourseTeacher[course: @clone_course, user: @clone_faculty]

    AddUserAsPeriodStudent[period: @copied_period, user: @copied_student]
    AddUserAsCourseTeacher[course: @copied_course, user: @copied_faculty]

    @faculty.account.confirmed_faculty!
    @clone_faculty.account.confirmed_faculty!
    @new_faculty.account.confirmed_faculty!
    @copied_faculty.account.confirmed_faculty!
  end

  before do
    @course.reload
    @period.reload

    @clone_course.reload
    @clone_period.reload

    @copied_course.reload
    @copied_period.reload

    @anonymous.reload
    @user.reload

    @student.reload
    @faculty.reload

    @new_faculty.reload

    @clone_student.reload
    @clone_faculty.reload

    @copied_student.reload
    @copied_faculty.reload
  end

  context 'original course' do
    # action, requestor are set in contexts
    subject(:allowed) { described_class.action_allowed?(action, requestor, @course) }

    context 'anonymous user' do
      let(:requestor) { @anonymous }

      [
        :index, :create_practice, :performance, :read, :read_task_plans, :export,
        :roster, :add_period, :update, :stats, :exercises, :clone, :create,
        :lms_connection_info, :lms_sync_scores, :lms_course_pair
      ].each do |test_action|
        context test_action.to_s do
          let(:action) { test_action }

          it { should eq false }
        end
      end
    end

    context 'regular user' do
      let(:requestor) { @user }

      context 'index' do
        let(:action) { :index }

        it { should eq true }
      end

      [
        :create_practice, :performance, :read, :read_task_plans, :export,
        :roster, :add_period, :update, :stats, :exercises, :clone, :create,
        :lms_connection_info, :lms_sync_scores, :lms_course_pair
      ].each do |test_action|
        context test_action.to_s do
          let(:action) { test_action }

          it { should eq false }
        end
      end
    end

    context 'student' do
      context 'in original course' do
        let(:requestor) { @student }

        [:index, :read, :create_practice, :performance].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq true }
          end
        end

        [
          :read_task_plans, :export, :roster, :add_period,
          :update, :stats, :exercises, :clone, :create,
          :lms_connection_info, :lms_sync_scores, :lms_course_pair
        ].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq false }
          end
        end
      end

      context 'in cloned course' do
        let(:requestor) { @clone_student }

        context 'index' do
          let(:action) { :index }

          it { should eq true }
        end

        [
          :create, :read, :create_practice, :performance, :read_task_plans,
          :export, :roster, :add_period, :update, :stats, :exercises, :clone,
          :lms_connection_info, :lms_sync_scores, :lms_course_pair
        ].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq false }
          end
        end
      end
    end

    context 'grant_tutor_access' do
      before { requestor.account.update_attribute :grant_tutor_access, true }

      context 'in original course' do
        let(:requestor) { @faculty }

        [
          :index, :create, :read, :create_practice, :performance, :read_task_plans,
          :export, :roster, :add_period, :update, :stats, :exercises, :clone,
          :lms_connection_info, :lms_sync_scores, :lms_course_pair
        ].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq true }
          end
        end
      end

      context 'in cloned course' do
        let(:requestor) { @clone_faculty }

        [ :index, :create, :read_task_plans ].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq true }
          end
        end

        [
          :read, :create_practice, :performance, :export, :roster,
          :add_period, :update, :stats, :exercises, :clone,
          :lms_connection_info, :lms_sync_scores, :lms_course_pair
        ].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq false }
          end
        end
      end

      context 'without a course' do
        let(:requestor) { @new_faculty }

        [ :index, :create ].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq true }
          end
        end

        [
          :read, :read_task_plans, :create_practice, :performance, :export,
          :roster, :add_period, :update, :stats, :exercises, :clone,
          :lms_connection_info, :lms_sync_scores, :lms_course_pair
        ].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq false }
          end
        end
      end
    end

    context 'confirmed faculty' do
      [ :college, :high_school, :k12_school, :home_school ].each do |school_type|
        context school_type.to_s do
          before { requestor.account.update_attribute :school_type, school_type }

          context 'in original course' do
            let(:requestor) { @faculty }

            [
              :index, :create, :read, :create_practice, :performance, :read_task_plans,
              :export, :roster, :add_period, :update, :stats, :exercises, :clone,
              :lms_connection_info, :lms_sync_scores, :lms_course_pair
            ].each do |test_action|
              context test_action.to_s do
                let(:action) { test_action }

                it { should eq true }
              end
            end
          end

          context 'in cloned course' do
            let(:requestor) { @clone_faculty }

            [ :index, :create, :read_task_plans ].each do |test_action|
              context test_action.to_s do
                let(:action) { test_action }

                it { should eq true }
              end
            end

            [
              :read, :create_practice, :performance, :export, :roster,
              :add_period, :update, :stats, :exercises, :clone,
              :lms_connection_info, :lms_sync_scores, :lms_course_pair
            ].each do |test_action|
              context test_action.to_s do
                let(:action) { test_action }

                it { should eq false }
              end
            end
          end

          context 'without a course' do
            let(:requestor) { @new_faculty }

            [ :index, :create ].each do |test_action|
              context test_action.to_s do
                let(:action) { test_action }

                it { should eq true }
              end
            end

            [
              :read, :read_task_plans, :create_practice, :performance, :export,
              :roster, :add_period, :update, :stats, :exercises, :clone,
              :lms_connection_info, :lms_sync_scores, :lms_course_pair
            ].each do |test_action|
              context test_action.to_s do
                let(:action) { test_action }

                it { should eq false }
              end
            end
          end
        end
      end

      [ :other_school_type ].each do |school_type|
        context school_type.to_s do
          before { requestor.account.update_attribute :school_type, school_type }

          context 'in original course' do
            let(:requestor) { @faculty }

            [ :create, :clone ].each do |test_action|
              context test_action.to_s do
                let(:action) { test_action }

                it { should eq false }
              end
            end

            [
              :index, :read, :create_practice, :performance, :read_task_plans,
              :export, :roster, :add_period, :update, :stats, :exercises,
              :lms_connection_info, :lms_sync_scores, :lms_course_pair
            ].each do |test_action|
              context test_action.to_s do
                let(:action) { test_action }

                it { should eq true }
              end
            end
          end

          context 'in cloned course' do
            let(:requestor) { @clone_faculty }

            [ :index, :read_task_plans ].each do |test_action|
              context test_action.to_s do
                let(:action) { test_action }

                it { should eq true }
              end
            end

            [
              :create, :read, :create_practice, :performance, :export,
              :roster, :add_period, :update, :stats, :exercises, :clone,
              :lms_connection_info, :lms_sync_scores, :lms_course_pair
            ].each do |test_action|
              context test_action.to_s do
                let(:action) { test_action }

                it { should eq false }
              end
            end
          end
        end
      end

      context 'foreign_school school_location' do
        before do
          requestor.account.college!
          requestor.account.foreign_school!
        end

        context 'in original course' do
          let(:requestor) { @faculty }

          [ :create, :clone ].each do |test_action|
            context test_action.to_s do
              let(:action) { test_action }

              it { should eq false }
            end
          end

          [
            :index, :read, :create_practice, :performance, :read_task_plans,
            :export, :roster, :add_period, :update, :stats, :exercises,
            :lms_connection_info, :lms_sync_scores, :lms_course_pair
          ].each do |test_action|
            context test_action.to_s do
              let(:action) { test_action }

              it { should eq true }
            end
          end
        end

        context 'in cloned course' do
          let(:requestor) { @clone_faculty }

          [ :index, :read_task_plans ].each do |test_action|
            context test_action.to_s do
              let(:action) { test_action }

              it { should eq true }
            end
          end

          [
            :create, :read, :create_practice, :performance, :export,
            :roster, :add_period, :update, :stats, :exercises, :clone,
            :lms_connection_info, :lms_sync_scores, :lms_course_pair
          ].each do |test_action|
            context test_action.to_s do
              let(:action) { test_action }

              it { should eq false }
            end
          end
        end
      end
    end
  end

  context 'cloned course' do
    # action, requestor are set in contexts
    subject(:allowed) { described_class.action_allowed?(action, requestor, @clone_course) }

    context 'anonymous user' do
      let(:requestor) { @anonymous }

      [
        :index, :read, :create_practice, :performance, :read_task_plans, :export,
        :roster, :add_period, :update, :stats, :exercises, :clone, :create,
        :lms_connection_info, :lms_sync_scores, :lms_course_pair
      ].each do |test_action|
        context test_action.to_s do
          let(:action) { test_action }

          it { should eq false }
        end
      end
    end

    context 'regular user' do
      let(:requestor) { @user }

      context 'index' do
        let(:action) { :index }

        it { should eq true }
      end

      [
        :read, :create_practice, :performance, :read_task_plans, :export,
        :roster, :add_period, :update, :stats, :exercises, :clone, :create,
        :lms_connection_info, :lms_sync_scores, :lms_course_pair
      ].each do |test_action|
        context test_action.to_s do
          let(:action) { test_action }

          it { should eq false }
        end
      end
    end

    context 'student' do
      context 'in original course' do
        let(:requestor) { @student }

        context 'index' do
          let(:action) { :index }

          it { should eq true }
        end

        [
          :create, :read, :create_practice, :performance, :read_task_plans,
          :export, :roster, :add_period, :update, :stats, :exercises, :clone,
          :lms_connection_info, :lms_sync_scores, :lms_course_pair
        ].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq false }
          end
        end
      end

      context 'in cloned course' do
        let(:requestor) { @clone_student }

        [:index, :read, :create_practice, :performance].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq true }
          end
        end

        [
          :read_task_plans, :export, :roster, :add_period,
          :update, :stats, :exercises, :clone, :create,
          :lms_connection_info, :lms_sync_scores, :lms_course_pair
        ].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq false }
          end
        end
      end
    end

    context 'grant_tutor_access' do
      before { requestor.account.update_attribute :grant_tutor_access, true }

      context 'in original course' do
        let(:requestor) { @faculty }

        [ :index, :create ].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq true }
          end
        end

        [
          :read, :create_practice, :performance, :read_task_plans, :export,
          :roster, :add_period, :update, :stats, :exercises, :clone,
          :lms_connection_info, :lms_sync_scores, :lms_course_pair
        ].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq false }
          end
        end
      end

      context 'in cloned course' do
        let(:requestor) { @clone_faculty }

        [
          :index, :create, :read, :create_practice, :performance, :read_task_plans,
          :export, :roster, :add_period, :update, :stats, :exercises, :clone,
          :lms_connection_info, :lms_sync_scores, :lms_course_pair
        ].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq true }
          end
        end
      end

      context 'without a course' do
        let(:requestor) { @new_faculty }

        [ :index, :create ].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq true }
          end
        end

        [
          :read, :create_practice, :performance, :read_task_plans, :export,
          :roster, :add_period, :update, :stats, :exercises, :clone,
          :lms_connection_info, :lms_sync_scores, :lms_course_pair
        ].each do |test_action|
          context test_action.to_s do
            let(:action) { test_action }

            it { should eq false }
          end
        end
      end
    end

    context 'confirmed faculty' do
      [ :college, :high_school, :k12_school, :home_school ].each do |school_type|
        context school_type.to_s do
          before { requestor.account.update_attribute :school_type, school_type }

          context 'in original course' do
            let(:requestor) { @faculty }

            [ :index, :create ].each do |test_action|
              context test_action.to_s do
                let(:action) { test_action }

                it { should eq true }
              end
            end

            [
              :read, :create_practice, :performance, :read_task_plans, :export,
              :roster, :add_period, :update, :stats, :exercises, :clone,
              :lms_connection_info, :lms_sync_scores, :lms_course_pair
            ].each do |test_action|
              context test_action.to_s do
                let(:action) { test_action }

                it { should eq false }
              end
            end
          end

          context 'in cloned course' do
            let(:requestor) { @clone_faculty }

            [
              :index, :create, :read, :create_practice, :performance, :read_task_plans,
              :export, :roster, :add_period, :update, :stats, :exercises, :clone,
              :lms_connection_info, :lms_sync_scores, :lms_course_pair
            ].each do |test_action|
              context test_action.to_s do
                let(:action) { test_action }

                it { should eq true }
              end
            end
          end

          context 'without a course' do
            let(:requestor) { @new_faculty }

            [ :index, :create ].each do |test_action|
              context test_action.to_s do
                let(:action) { test_action }

                it { should eq true }
              end
            end

            [
              :read, :create_practice, :performance, :read_task_plans, :export,
              :roster, :add_period, :update, :stats, :exercises, :clone,
              :lms_connection_info, :lms_sync_scores, :lms_course_pair
            ].each do |test_action|
              context test_action.to_s do
                let(:action) { test_action }

                it { should eq false }
              end
            end
          end
        end
      end

      [ :other_school_type ].each do |school_type|
        context school_type.to_s do
          before { requestor.account.update_attribute :school_type, school_type }

          context 'in original course' do
            let(:requestor) { @faculty }

            context 'index' do
              let(:action) { :index }

              it { should eq true }
            end

            [
              :read, :create, :create_practice, :performance, :read_task_plans,
              :export, :roster, :add_period, :update, :stats, :exercises, :clone,
              :lms_connection_info, :lms_sync_scores, :lms_course_pair
             ].each do |test_action|
              context test_action.to_s do
                let(:action) { test_action }

                it { should eq false }
              end
            end
          end

          context 'in cloned course' do
            let(:requestor) { @clone_faculty }

            [ :create, :clone ].each do |test_action|
              context test_action.to_s do
                let(:action) { test_action }

                it { should eq false }
              end
            end

            [
              :index, :read, :create_practice, :performance, :read_task_plans,
              :export, :roster, :add_period, :update, :stats, :exercises,
              :lms_connection_info, :lms_sync_scores, :lms_course_pair
            ].each do |test_action|
              context test_action.to_s do
                let(:action) { test_action }

                it { should eq true }
              end
            end
          end
        end
      end
    end
  end

  context 'course copied from another environment' do
    # action, requestor are set in contexts
    subject(:allowed) { described_class.action_allowed?(action, requestor, @copied_course) }

    context 'anonymous user' do
      let(:requestor) { @anonymous }

      [
        :index, :read, :create_practice, :performance, :read_task_plans, :export,
        :roster, :add_period, :update, :stats, :exercises, :clone, :create,
        :lms_connection_info, :lms_sync_scores, :lms_course_pair
      ].each do |test_action|
        context test_action.to_s do
          let(:action) { test_action }

          it { should eq false }
        end
      end
    end

    context 'regular user' do
      let(:requestor) { @user }

      context 'index' do
        let(:action) { :index }

        it { should eq true }
      end

      [
        :read, :create_practice, :performance, :read_task_plans, :export,
        :roster, :add_period, :update, :stats, :exercises, :clone, :create,
        :lms_connection_info, :lms_sync_scores, :lms_course_pair
      ].each do |test_action|
        context test_action.to_s do
          let(:action) { test_action }

          it { should eq false }
        end
      end
    end

    context 'student' do
      let(:requestor) { @copied_student }

      [:index, :read, :create_practice, :performance].each do |test_action|
        context test_action.to_s do
          let(:action) { test_action }

          it { should eq true }
        end
      end

      [
        :read_task_plans, :export, :roster, :add_period,
        :update, :stats, :exercises, :clone, :create,
        :lms_connection_info, :lms_sync_scores, :lms_course_pair
      ].each do |test_action|
        context test_action.to_s do
          let(:action) { test_action }

          it { should eq false }
        end
      end
    end

    context 'grant_tutor_access' do
      before { requestor.account.update_attribute :grant_tutor_access, true }

      let(:requestor) { @copied_faculty }

      [
        :index, :create, :read, :create_practice, :performance, :read_task_plans,
        :export, :roster, :add_period, :update, :stats, :exercises, :clone, :lms_connection_info
      ].each do |test_action|
        context test_action.to_s do
          let(:action) { test_action }

          it { should eq true }
        end
      end

      [ :lms_sync_scores, :lms_course_pair ].each do |test_action|
        context test_action.to_s do
          let(:action) { test_action }

          it { should eq false }
        end
      end
    end

    context 'confirmed faculty' do
      [ :college, :high_school, :k12_school, :home_school ].each do |school_type|
        context school_type.to_s do
          before { requestor.account.update_attribute :school_type, school_type }

          let(:requestor) { @copied_faculty }

          [
            :index, :create, :read, :create_practice, :performance, :read_task_plans,
            :export, :roster, :add_period, :update, :stats, :exercises, :clone, :lms_connection_info
          ].each do |test_action|
            context test_action.to_s do
              let(:action) { test_action }

              it { should eq true }
            end
          end

          [ :lms_sync_scores, :lms_course_pair ].each do |test_action|
            context test_action.to_s do
              let(:action) { test_action }

              it { should eq false }
            end
          end
        end
      end

      [ :other_school_type ].each do |school_type|
        context school_type.to_s do
          before { requestor.account.update_attribute :school_type, school_type }

          let(:requestor) { @copied_faculty }

          [ :create, :clone ].each do |test_action|
            context test_action.to_s do
              let(:action) { test_action }

              it { should eq false }
            end
          end

          [
            :index, :read, :create_practice, :performance, :read_task_plans,
            :export, :roster, :add_period, :update, :stats, :exercises, :lms_connection_info
          ].each do |test_action|
            context test_action.to_s do
              let(:action) { test_action }

              it { should eq true }
            end
          end

          [ :lms_sync_scores, :lms_course_pair ].each do |test_action|
            context test_action.to_s do
              let(:action) { test_action }

              it { should eq false }
            end
          end
        end
      end
    end
  end
end
