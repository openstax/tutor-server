require 'rails_helper'

module Doorkeeper
  RSpec.describe ApplicationAccessPolicy do
    let!(:user)        { FactoryGirl.create(:user) }
    let!(:admin)        { FactoryGirl.create(:user, :administrator) }
    let!(:application) { FactoryGirl.create(:doorkeeper_application) }

    context 'index, read, create, update, destroy' do
      it 'can be accessed by humans administrators only' do
        expect(ApplicationAccessPolicy.action_allowed?(:index, user, Application)).to eq false
        expect(ApplicationAccessPolicy.action_allowed?(:create, user, application)).to eq false
        expect(ApplicationAccessPolicy.action_allowed?(:read, user, application)).to eq false
        expect(ApplicationAccessPolicy.action_allowed?(:update, user, application)).to eq false
        expect(ApplicationAccessPolicy.action_allowed?(:destroy, user, application)).to eq false

        expect(ApplicationAccessPolicy.action_allowed?(:index, admin, Application)).to eq true
        expect(ApplicationAccessPolicy.action_allowed?(:create, admin, application)).to eq true
        expect(ApplicationAccessPolicy.action_allowed?(:read, admin, application)).to eq true
        expect(ApplicationAccessPolicy.action_allowed?(:update, admin, application)).to eq true
        expect(ApplicationAccessPolicy.action_allowed?(:destroy, admin, application)).to eq true

        expect(ApplicationAccessPolicy.action_allowed?(:index, application, Application)).to eq false
        expect(ApplicationAccessPolicy.action_allowed?(:create, user, application)).to eq false
        expect(ApplicationAccessPolicy.action_allowed?(:read, application, application)).to eq false
        expect(ApplicationAccessPolicy.action_allowed?(:update, application, application)).to eq false
        expect(ApplicationAccessPolicy.action_allowed?(:destroy, application, application)).to eq false
      end
    end
  end
end
