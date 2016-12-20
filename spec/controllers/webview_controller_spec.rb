require 'rails_helper'

RSpec.describe WebviewController, type: :controller do

  let!(:contract)       { FinePrint::Contract.create!(name: 'general_terms_of_use',
                                                      title: 'General Terms of Use',
                                                      content: Faker::Lorem.paragraphs,
                                                      version: 10) }
  let(:new_user)        { FactoryGirl.create(:user, skip_terms_agreement: true) }
  let(:registered_user) { FactoryGirl.create(:user) }

  describe 'GET home' do
    it 'renders a static page for anonymous' do
      get :home
      expect(response).to have_http_status(:success)
    end

    it 'redirects logged in users to the dashboard' do
      controller.sign_in new_user
      get :home
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'redirect to CC landing page when param set' do
      get :home, cc: "1"
      expect(response).to redirect_to('http://cc.openstax.org')
    end
  end

  describe 'GET *anything' do
    it 'requires a user' do
      get :index
      expect(response).to redirect_to(controller.send(:openstax_accounts_login_path))
    end

    it 'requires agreement to contracts' do
      controller.sign_in new_user
      get :index
      expect(response).to have_http_status(:found)
    end

    context "as a signed in user" do
      render_views

      it 'sets boostrap data in script tag' do
        controller.sign_in registered_user
        fake_flash(:alert, "Alarm!")

        get :index
        expect(response).to have_http_status(:success)
        doc = Nokogiri::HTML(response.body)
        data = ::JSON.parse(doc.css('body script#tutor-boostrap-data').inner_text)
        expect(data).to include({
          'courses'=> CollectCourseInfo[user: registered_user, with: [:roles, :periods]].as_json,
          'user' => Api::V1::UserRepresenter.new(registered_user).as_json,
          'flash' => {alert: "Alarm!"}.as_json
        })
      end
    end

  end


end
