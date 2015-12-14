require 'rails_helper'

RSpec.describe EcosystemAccessPolicy, type: :access_policy do
  let(:course)            { CreateCourse.call(name: 'Physics 401').course }
  let(:period)            { CreatePeriod.call(course: course).period }

  let(:student)           { FactoryGirl.create(:user) }
  let(:teacher)           { FactoryGirl.create(:user) }
  let(:content_analyst)   { FactoryGirl.create(:user, :content_analyst) }

  let(:ecosystem)         {
    content_ecosystem = FactoryGirl.create(:content_ecosystem)
    ecosystem_strategy = ::Content::Strategies::Direct::Ecosystem.new(content_ecosystem)
    ::Content::Ecosystem.new(strategy: ecosystem_strategy)
  }

  before(:each) do
    AddUserAsCourseTeacher.call(course: course, user: teacher)
    AddUserAsPeriodStudent.call(period: period, user: student)
    AddEcosystemToCourse.call(ecosystem: ecosystem, course: course)
  end

  # action, requestor are set in contexts
  subject(:allowed) { described_class.action_allowed?(action, requestor, ecosystem) }

  context 'anonymous users' do
    let(:requestor) { User::User.anonymous }

    [:index, :readings, :exercises].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be false }
      end
    end
  end

  context 'regular users' do
    let(:requestor) { FactoryGirl.create(:user) }

    [:index, :readings, :exercises].each do |test_action|
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

    [:index, :exercises].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be false }
      end
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

    context 'index' do
      let(:action) { :index }
      it { should be false }
    end
  end

  context 'content analysts' do
    let(:requestor) { content_analyst }

    [:index, :readings, :exercises].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should be true }
      end
    end
  end
end
