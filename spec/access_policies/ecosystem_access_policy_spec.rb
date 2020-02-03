require 'rails_helper'

RSpec.describe EcosystemAccessPolicy, type: :access_policy, speed: :medium do
  let(:course)          { FactoryBot.create :course_profile_course }
  let(:period)          { FactoryBot.create :course_membership_period, course: course }

  let(:student)         { FactoryBot.create(:user_profile) }
  let(:teacher)         { FactoryBot.create(:user_profile) }

  let(:content_analyst) { FactoryBot.create(:user_profile, :content_analyst) }
  let(:admin)           { FactoryBot.create(:user_profile, :administrator) }

  let(:ecosystem)       { FactoryBot.create(:content_ecosystem) }

  before(:each) do
    AddUserAsCourseTeacher[course: course, user: teacher]
    AddUserAsPeriodStudent[period: period, user: student]
    AddEcosystemToCourse[ecosystem: ecosystem, course: course]
  end

  # action, requestor are set in contexts
  subject(:allowed) { described_class.action_allowed?(action, requestor, ecosystem) }

  context 'anonymous users' do
    let(:requestor) { User::Models::Profile.anonymous }

    [:index, :readings, :exercises].each do |test_action|
      context "#{test_action}" do
        let(:action) { test_action }
        it { should eq false }
      end
    end
  end

  context 'regular users' do
    let(:requestor) { FactoryBot.create(:user_profile) }

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

  [:index, :create, :update, :destroy, :manifest, :readings, :exercises].each do |test_action|
    context 'admins' do
      let(:requestor) { admin }
      context "#{test_action}" do
        let(:action) { test_action }
        it { should eq true }
      end
    end

    context 'content analysts' do
      let(:requestor) { content_analyst }

      context "#{test_action}" do
        let(:action) { test_action }
        it { should eq true }
      end
    end
  end

end
