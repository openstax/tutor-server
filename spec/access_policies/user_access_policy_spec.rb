require 'rails_helper'

RSpec.describe UserAccessPolicy do
  let!(:anon)        { AnonymousUser.instance }
  let!(:user)        { FactoryGirl.create(:user) }
  let!(:application) { FactoryGirl.create(:doorkeeper_application) }

  context 'index' do
    it 'cannot be accessed by anonymous users' do
      expect(UserAccessPolicy.action_allowed?(:index, anon, User)).to eq false
    end

    it 'can be accessed by applications and human users' do
      expect(UserAccessPolicy.action_allowed?(:index, user, User)).to eq true

      expect(UserAccessPolicy.action_allowed?(:index, application, User)).to eq true
    end
  end

  context 'show, update and destroy' do
    it 'cannot be accessed by anonymous users or applications' do
      expect(UserAccessPolicy.action_allowed?(:read, anon, user)).to eq false
      expect(UserAccessPolicy.action_allowed?(:update, anon, user)).to eq false
      expect(UserAccessPolicy.action_allowed?(:destroy, anon, user)).to eq false

      expect(UserAccessPolicy.action_allowed?(:read, application, user)).to eq false
      expect(UserAccessPolicy.action_allowed?(:update, application, user)).to eq false
      expect(UserAccessPolicy.action_allowed?(:destroy, application, user)).to eq false
    end

    it 'can be accessed by humans users' do
      expect(UserAccessPolicy.action_allowed?(:read, user, user)).to eq true
      expect(UserAccessPolicy.action_allowed?(:update, user, user)).to eq true
      expect(UserAccessPolicy.action_allowed?(:destroy, user, user)).to eq true
    end
  end
end
