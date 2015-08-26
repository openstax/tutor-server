require 'rails_helper'

RSpec.describe EcosystemAccessPolicy, type: :access_policy do
  let(:course)    { CreateCourse[name: 'Physics 401'] }
  let(:period)    { CreatePeriod[course: course] }

  let(:student)   { FactoryGirl.create(:user_profile) }
  let(:teacher)   { FactoryGirl.create(:user_profile) }

  let(:ecosystem) {
    content_ecosystem = FactoryGirl.create(:content_ecosystem)
    ecosystem_strategy = ::Content::Strategies::Direct::Ecosystem.new(content_ecosystem)
    ::Content::Ecosystem.new(strategy: ecosystem_strategy)
  }

  before(:each) do
    AddUserAsCourseTeacher[course: course, user: teacher.entity_user]
    AddUserAsPeriodStudent[period: period, user: student.entity_user]
    AddEcosystemToCourse[ecosystem: ecosystem, course: course]
  end

  # action, requestor are set in contexts
  subject(:allowed) { described_class.action_allowed?(action, requestor, ecosystem) }

  context 'anonymous users' do
    let(:requestor) { UserProfile::Models::AnonymousUser.instance }

    [:readings, :exercises].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be false }
      end
    end
  end

  context 'regular users' do
    let(:requestor) { FactoryGirl.create(:user_profile) }

    [:readings, :exercises].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be false }
      end
    end
  end

  context 'students' do
    let(:requestor) { student }

    context 'readings' do
      let(:action) { :readings }
      it { should be true }
    end

    context 'exercises' do
      let(:action) { :exercises }
      it { should be false }
    end
  end

  context 'teachers' do
    let(:requestor) { teacher }

    [:readings, :exercises].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be true }
      end
    end
  end
end
