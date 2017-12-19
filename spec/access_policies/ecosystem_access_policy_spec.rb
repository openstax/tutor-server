require 'rails_helper'

RSpec.describe EcosystemAccessPolicy, type: :access_policy, speed: :medium do
  let(:course)          { FactoryBot.create :course_profile_course }
  let(:period)          { FactoryBot.create :course_membership_period, course: course }

  let(:student)         { FactoryBot.create(:user) }
  let(:teacher)         { FactoryBot.create(:user) }

  let(:content_analyst) { FactoryBot.create(:user, :content_analyst) }
  let(:admin)           { FactoryBot.create(:user, :administrator) }

  let(:ecosystem)       do
    content_ecosystem = FactoryBot.create(:content_ecosystem)
    ecosystem_strategy = ::Content::Strategies::Direct::Ecosystem.new(content_ecosystem)
    ::Content::Ecosystem.new(strategy: ecosystem_strategy)
  end

  before(:each) do
    AddUserAsCourseTeacher[course: course, user: teacher]
    AddUserAsPeriodStudent[period: period, user: student]
    AddEcosystemToCourse[ecosystem: ecosystem, course: course]
  end

  # action, requestor are set in contexts
  subject(:allowed) { described_class.action_allowed?(action, requestor, ecosystem) }

  context 'anonymous users' do
    let(:requestor) { User::User.anonymous }

    [:index, :readings, :exercises].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should eq false }
      end
    end
  end

  context 'regular users' do
    let(:requestor) { FactoryBot.create(:user) }

    [:index, :readings, :exercises].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should eq false }
      end
    end
  end

  context 'students' do
    let(:requestor) { student }

    context 'readings' do
      let(:action) { :readings }
      it { should eq true }
    end

    [:index, :exercises].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should eq false }
      end
    end
  end

  context 'teachers' do
    let(:requestor) { teacher }

    [:readings, :exercises].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should eq true }
      end
    end

    context 'index' do
      let(:action) { :index }
      it { should eq false }
    end
  end

  context 'content analysts' do
    let(:requestor) { content_analyst }

    context 'index' do
      let(:action) { :index }
      it { should eq true }
    end

    [:create, :update, :destroy, :manifest, :readings, :exercises].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should eq false }
      end
    end
  end

  context 'admins' do
    let(:requestor) { admin }

    [:index, :create, :update, :destroy, :manifest, :readings, :exercises].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should eq true }
      end
    end
  end
end
