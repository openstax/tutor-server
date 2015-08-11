require 'rails_helper'

RSpec.describe CourseAccessPolicy, :type => :access_policy do
  let(:course) { CreateCourse[name: 'Physics 401'] }
  let(:period) { CreatePeriod[course: course] }

  let(:student) { FactoryGirl.create(:user_profile) }
  let(:teacher) { FactoryGirl.create(:user_profile) }

  before do
    AddUserAsCourseTeacher[course: course, user: teacher.entity_user]
    AddUserAsPeriodStudent[period: period, user: student.entity_user]
  end

  # action, requestor are set in contexts
  subject(:allowed) { CourseAccessPolicy.action_allowed?(action, requestor, course) }

  context 'anonymous users' do
    let(:requestor) { UserProfile::Models::AnonymousUser.instance }

    [:index, :read, :readings, :task_plans,
     :exercises, :export, :roster].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be false }
      end
    end
  end

  context 'regular users' do
    let(:requestor) { FactoryGirl.create(:user_profile) }

    context ":index" do
      let(:action) { :index }
      it { should be true }
    end

    [:read, :readings, :task_plans,
     :exercises, :export, :roster].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be false }
      end
    end
  end

  context 'students' do
    let(:requestor) { student }

    [:index, :read, :readings, :task_plans].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be true }
      end
    end

    [:exercises, :export, :roster].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be false }
      end
    end
  end

  context 'teachers' do
    let(:requestor) { teacher }

    [:index, :read, :readings, :task_plans,
     :exercises, :export, :roster].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be true }
      end
    end
  end
end
