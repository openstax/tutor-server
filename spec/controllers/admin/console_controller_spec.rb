require 'rails_helper'

RSpec.describe Admin::ConsoleController do
  describe 'GET #index' do
    it 'responds with success' do
      profile = FactoryGirl.create(:user_profile, :administrator)
      strategy = User::Strategies::Direct::User.new(profile)
      admin = User::User.new(strategy: strategy)

      controller.sign_in(admin)

      get :index

      expect(response).to be_ok
    end
  end
end
