require 'rails_helper'

RSpec.describe WebviewController, :type => :controller do

  let!(:new_user)        { FactoryGirl.create(:user) }
  let!(:registered_user) { FactoryGirl.create(:user, :agreed_to_terms) }
  let!(:contract)        { FinePrint::Contract.create!(name: 'general_terms_of_use', title: 'General Terms of Use', content: Faker::Lorem.paragraphs, version: 10) }

  describe 'GET index' do
    it 'requires a user' do
      get :index
      expect(response).to redirect_to(controller.send(:with_interceptor) {
                            url_for(openstax_accounts.login_path) })
    end

    it 'requires agreement to contracts' do
      controller.sign_in new_user
      get :index
      expect(response).to redirect_to(controller.send(:with_interceptor) { url_for(
                            fine_print.contract_signatures_path(FinePrint::Contract.last)) })
    end

    it 'returns http success' do
      controller.sign_in registered_user
      get :index
      expect(response).to have_http_status(:success)
    end
  end

end
