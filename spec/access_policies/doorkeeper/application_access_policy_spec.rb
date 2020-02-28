require 'rails_helper'

module Doorkeeper
  RSpec.describe ApplicationAccessPolicy, type: :access_policy do
    let(:anon)        { User::Models::Profile.anonymous }
    let(:user)        { FactoryBot.create(:user_profile) }
    let(:admin)       { FactoryBot.create(:user_profile, :administrator) }
    let(:application) { FactoryBot.create(:doorkeeper_application) }

    context 'index, read, create, update, destroy' do
      it 'cannot be accessed by non-administrators' do
        expect(ApplicationAccessPolicy.action_allowed?(:index, anon, Application)).to eq false
        expect(ApplicationAccessPolicy.action_allowed?(:create, anon, application)).to eq false
        expect(ApplicationAccessPolicy.action_allowed?(:read, anon, application)).to eq false
        expect(ApplicationAccessPolicy.action_allowed?(:update, anon, application)).to eq false
        expect(ApplicationAccessPolicy.action_allowed?(:destroy, anon, application)).to eq false

        expect(ApplicationAccessPolicy.action_allowed?(:index, user, Application)).to eq false
        expect(ApplicationAccessPolicy.action_allowed?(:create, user, application)).to eq false
        expect(ApplicationAccessPolicy.action_allowed?(:read, user, application)).to eq false
        expect(ApplicationAccessPolicy.action_allowed?(:update, user, application)).to eq false
        expect(ApplicationAccessPolicy.action_allowed?(:destroy, user, application)).to eq false

        expect(ApplicationAccessPolicy.action_allowed?(:index, application, Application)).to eq false
        expect(ApplicationAccessPolicy.action_allowed?(:create, user, application)).to eq false
        expect(ApplicationAccessPolicy.action_allowed?(:read, application, application)).to eq false
        expect(ApplicationAccessPolicy.action_allowed?(:update, application, application)).to eq false
        expect(ApplicationAccessPolicy.action_allowed?(:destroy, application, application)).to eq false
      end

      it 'can be accessed by human administrators only' do
        expect(ApplicationAccessPolicy.action_allowed?(:index, admin, Application)).to eq true
        expect(ApplicationAccessPolicy.action_allowed?(:create, admin, application)).to eq true
        expect(ApplicationAccessPolicy.action_allowed?(:read, admin, application)).to eq true
        expect(ApplicationAccessPolicy.action_allowed?(:update, admin, application)).to eq true
        expect(ApplicationAccessPolicy.action_allowed?(:destroy, admin, application)).to eq true
      end
    end
  end
end
