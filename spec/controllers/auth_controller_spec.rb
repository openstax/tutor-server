require 'rails_helper'

RSpec.describe AuthController, type: :controller do

  let(:user)     { FactoryGirl.create(:user) }
  let(:new_user) {  FinePrint::Contract.create!(name: 'general_terms_of_use',
                                                title: 'General Terms of Use',
                                                content: Faker::Lorem.paragraphs,
                                                version: 10)
    FactoryGirl.create(:user, skip_terms_agreement: true)
  }

  context "as an non-signed in user" do

    context "when not using stubbed authentication" do

      before(:each) {
        @stubbing_value = OpenStax::Accounts.configuration.enable_stubbing
        OpenStax::Accounts.configuration.enable_stubbing = false
      }
      after(:each) {
        OpenStax::Accounts.configuration.enable_stubbing = @stubbing_value
      }

      it 'allows access to iframe and redirects to accounts' do
        get :iframe
        expect(session[:accounts_return_to]).to eq(authenticate_via_iframe_url)
        expect(response).to redirect_to(controller.openstax_accounts.login_url)
      end

    end

    context "when using stubbing" do
      it 'allows access to iframe and redirects to stub url' do
        get :iframe
        expect(session[:accounts_return_to]).to eq(authenticate_via_iframe_url)
        expect(response).to redirect_to(controller.openstax_accounts.dev_accounts_url)
      end
    end

  end


  context "as an signed in user" do
    render_views

    it 'renders status info' do
      controller.sign_in user
      get :iframe
      expect(response.header['X-Frame-Options']).to be_nil
      expect(session[:accounts_return_to]).to be_nil
      expect(assigns(:status)).not_to be_nil
      expect(response.body).to include('window.parent.postMessage')
    end

    it 'requires agreeing to terms' do
      controller.sign_in new_user
      get :iframe
      expect(response).to redirect_to(/#{pose_terms_path}/)
    end

  end

end
