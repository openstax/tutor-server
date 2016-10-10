require "rails_helper"

RSpec.describe Api::V1::UsersController, type: :controller, api: true, version: :v1 do

  let(:application)    { FactoryGirl.create :doorkeeper_application }
  let(:user_1)         { FactoryGirl.create(:user) }
  let(:user_1_token)   { FactoryGirl.create :doorkeeper_access_token,
                                            application: application,
                                            resource_owner_id: user_1.id }

  let(:admin)          { FactoryGirl.create(:user, :administrator) }
  let(:admin_token)    { FactoryGirl.create :doorkeeper_access_token,
                                            application: application,
                                            resource_owner_id: admin.id }

  let(:userless_token) { FactoryGirl.create :doorkeeper_access_token,
                                            application: application,
                                            resource_owner_id: nil }

  describe "#show" do
    context "caller has an authorization token" do
      it "should return an ok (200) code" do
        api_get :show, user_1_token
        expect(response.code).to eq('200')
        payload = JSON.parse(response.body)
        expect(payload).to eq(
          "name" => user_1.name,
          'is_admin' => false,
          'is_customer_service' => false,
          'is_content_analyst' => false,
          'profile_url' => Addressable::URI.join(
            OpenStax::Accounts.configuration.openstax_accounts_url,
            '/profile').to_s
        )
      end

      it 'returns is_admin flag correctly' do
        api_get :show, admin_token
        expect(response.code).to eq('200')
        payload = JSON.parse(response.body)
        expect(payload).to eq(
          "name" => admin.name,
          'is_admin' => true,
          'is_customer_service' => false,
          'is_content_analyst' => false,
          'profile_url' => Addressable::URI.join(
            OpenStax::Accounts.configuration.openstax_accounts_url,
            '/profile').to_s
        )
      end
    end

    context "caller does not have an authorization token" do
      it "should return a forbidden (403) code" do
        api_get :show, nil
        expect(response.code).to eq('403')
      end
    end

    context "caller has an application/client credentials authorization token" do
      it "should return a forbidden (403) code" do
        api_get :show, userless_token
        expect(response.code).to eq('403')
      end
    end
  end

  describe "#ui-settings" do
    it 'returns api_error when previous is invalid' do
      api_put :ui_settings, user_1_token, raw_post_data: {
                'ui_settings' => {is_open: false, answer: 42}
              }.to_json
      expect(response.code).to eq('422')
      expect(response.body).to include('out-of-band update detected')
    end

    it "saves to profile" do
      api_put :ui_settings, user_1_token, raw_post_data: {
                'previous_ui_settings' => {},
                'ui_settings' => {is_open: false, answer: 42}
              }.to_json
      expect(response.code).to eq('200')
      expect(user_1.to_model.reload.ui_settings).to eq({'is_open' => false, 'answer' => 42})
    end

  end

end
