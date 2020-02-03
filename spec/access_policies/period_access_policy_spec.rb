require 'rails_helper'

RSpec.describe PeriodAccessPolicy, type: :access_policy, speed: :medium do
  let(:course)  { FactoryBot.create :course_profile_course }
  let(:period)  { FactoryBot.create :course_membership_period, course: course }

  let(:anon)    { User::Models::AnonymousProfile.instance }
  let(:user)    { FactoryBot.create(:user_profile) }
  let(:student) { FactoryBot.create(:user_profile) }
  let(:teacher) { FactoryBot.create(:user_profile) }

  before do
    AddUserAsCourseTeacher[course: course, user: teacher]
    AddUserAsPeriodStudent[period: period, user: student]
  end

  # action, requestor are set in contexts
  subject(:allowed) { described_class.action_allowed?(action, requestor, period) }

  context 'anonymous users' do
    let(:requestor) { anon }

    [:read, :create, :update, :destroy, :restore, :teacher_student].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should eq false }
      end
    end
  end

  context 'regular users' do
    let(:requestor) { user }

    [:read, :create, :update, :destroy, :restore, :teacher_student].each do |test_action|
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

    [:create, :update, :destroy, :restore, :teacher_student].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should eq false }
      end
    end
  end

  context 'teachers' do
    let(:requestor) { teacher }

    [:read, :create, :update, :destroy, :restore, :teacher_student].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should eq true }
      end
    end
  end
end
