require 'rails_helper'

RSpec.describe AuthController, type: :controller do

  let(:user)        { FactoryGirl.create(:user) }

  context "as an non-signed in user" do

    it 'requires back paramter to be present' do
      get :login
      expect(response).to have_http_status(:bad_request)
    end

    it 'allows access to login and redirects to accounts' do
      get :login, back: 'http://test.com/'
      expect(session[:r]).to eq('http://test.com/')
      expect(response).to redirect_to(controller.openstax_accounts.login_url)
    end

  end

  context "as an signed in user" do

    it 'allows access to login and redirects back to return url' do
      controller.sign_in user
      get :login, {}, {r: 'http://cnx.org/a-good-book'}
      expect(response).to redirect_to('http://cnx.org/a-good-book')
    end

  end

end
