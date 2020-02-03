require 'rails_helper'

RSpec.describe RoleAccessPolicy, type: :access_policy do
  let(:anon)       { User::Models::AnonymousProfile.instance }
  let(:other_user) { FactoryBot.create(:user_profile) }
  let(:user)       { FactoryBot.create(:user_profile) }
  let(:role)       { FactoryBot.create(:entity_role, profile: user) }

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
