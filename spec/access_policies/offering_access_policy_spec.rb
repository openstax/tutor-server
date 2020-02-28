require 'rails_helper'

RSpec.describe OfferingAccessPolicy, type: :access_policy do
  let(:offering)    { FactoryBot.create :catalog_offering }

  let(:anon)        { User::Models::Profile.anonymous }
  let(:user)        { FactoryBot.create(:user_profile) }
  let(:application) { FactoryBot.create(:doorkeeper_application) }
  let(:teacher)     do
    FactoryBot.create(:user_profile).tap do |user|
      user.account.confirmed_faculty!
      user.account.other_school_type!
    end
  end
  let(:faculty)     do
    FactoryBot.create(:user_profile).tap do |user|
      user.account.confirmed_faculty!
      user.account.college!
    end
  end

  # action, requestor are set in contexts
  subject(:allowed) { described_class.action_allowed?(action, requestor, offering) }

  context 'anonymous user' do
    let(:requestor) { anon }

    [:index, :read, :create_course].each do |test_action|
      context test_action.to_s do
        let(:action) { test_action }

        it { should eq false }
      end
    end
  end

  context 'regular user' do
    let(:requestor) { user }

    [:index, :read, :create_course].each do |test_action|
      context test_action.to_s do
        let(:action) { test_action }

        it { should eq false }
      end
    end
  end

  context 'application' do
    let(:requestor) { application }

    [:index, :read, :create_course].each do |test_action|
      context test_action.to_s do
        let(:action) { test_action }

        it { should eq false }
      end
    end
  end

  context 'verified non-college teacher' do
    let(:requestor) { teacher }

    [:index, :read, :create_course].each do |test_action|
      context test_action.to_s do
        let(:action) { test_action }

        it { should eq false }
      end
    end
  end

  context 'verified faculty' do
    let(:requestor) { faculty }

    context 'index' do
      let(:action) { :index }

      it { should eq true }
    end

    context 'available offering' do
      [:read, :create_course].each do |test_action|
        context test_action.to_s do
          let(:action) { test_action }

          it { should eq true }
        end
      end
    end

    context 'unavailable offering' do
      before{ offering.update_attribute :is_available, false }

      [:create_course].each do |test_action|
        context test_action.to_s do
          let(:action) { test_action }

          it { should eq false }
        end
      end
    end

  end
end
