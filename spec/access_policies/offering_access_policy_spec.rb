require 'rails_helper'

RSpec.describe OfferingAccessPolicy, type: :access_policy do
  let(:offering)    { FactoryBot.create :catalog_offering }

  let(:anon)        { User::Models::Profile.anonymous }
  let(:user)        { FactoryBot.create(:user_profile) }
  let(:application) { FactoryBot.create(:doorkeeper_application) }
  let(:faculty)     do
    FactoryBot.create(:user_profile).tap { |user| user.account.confirmed_faculty! }
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

  context 'explicitly marked as grant_tutor_access' do
    let(:requestor) { FactoryBot.create(:user_profile).tap{ |user| user.account.update_attributes(grant_tutor_access: true) } }

    [:index, :read, :create_course].each do |test_action|
      context test_action.to_s do
        let(:action) { test_action }

        it { should eq true }
      end
    end
  end

  context 'verified faculty' do
    let(:requestor) { faculty }

    [ :college, :high_school, :k12_school, :home_school ].each do |school_type|
      context school_type.to_s do
        before { requestor.account.update_attribute :school_type, school_type }

        context 'index' do
          let(:action) { :index }

          it { should eq true }
        end

        context 'available offering' do
          [ :read, :create_preview, :create_course ].each do |test_action|
            context test_action.to_s do
              let(:action) { test_action }

              it { should eq true }
            end
          end
        end

        context 'unavailable preview' do
          before { offering.update_attribute :is_preview_available, false }

          context 'create_preview' do
            let(:action) { :create_preview }

            it { should eq false }
          end
        end

        context 'unavailable offering' do
          before { offering.update_attribute :is_available, false }

          context 'create_course' do
            let(:action) { :create_course }

            it { should eq false }
          end
        end
      end
    end

    context 'other_school_type' do
      before { requestor.account.other_school_type! }

      [ :index, :read, :create_course ].each do |test_action|
        context test_action.to_s do
          let(:action) { test_action }

          it { should eq false }
        end
      end
    end

    context 'foreign_school school_location' do
      before do
        requestor.account.college!
        requestor.account.foreign_school!
      end

      [ :index, :read, :create_course ].each do |test_action|
        context test_action.to_s do
          let(:action) { test_action }

          it { should eq false }
        end
      end
    end
  end
end
