require 'rails_helper'

RSpec.describe RoleAccessPolicy, type: :access_policy do
  let(:anon)       do
    profile = User::Models::AnonymousProfile.instance
    strategy = User::Strategies::Direct::AnonymousUser.new(profile)
    User::User.new(strategy: strategy)
  end
  let(:other_user) { FactoryBot.create(:user) }
  let(:user)       { FactoryBot.create(:user) }
  let(:role)       { FactoryBot.create(:entity_role, profile: user.to_model) }

  # action, requestor are set in contexts
  subject(:allowed) { described_class.action_allowed?(action, requestor, role) }

  context 'anonymous users' do
    let(:requestor) { anon }

    context 'become' do
      let(:action) { :become }

      it { should eq false }
    end
  end

  context 'unauthorized users' do
    let(:requestor) { other_user }

    context 'become' do
      let(:action) { :become }

      it { should eq false }
    end
  end

  context 'the user that owns the role' do
    let(:requestor) { user }

    context 'become' do
      let(:action) { :become }

      it { should eq true }
    end
  end
end
