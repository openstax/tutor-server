require "rails_helper"

RSpec.describe Api::V1::UsersController, type: :request, api: true, version: :v1 do
  let(:application)    { FactoryBot.create :doorkeeper_application }
  let(:user_1)         { FactoryBot.create(:user_profile) }
  let(:user_1_token)   { FactoryBot.create :doorkeeper_access_token,
                                            application: application,
                                            resource_owner_id: user_1.id }

  let(:admin)          { FactoryBot.create(:user_profile, :administrator) }
  let(:admin_token)    do
    FactoryBot.create :doorkeeper_access_token,
                       application: application,
                       resource_owner_id: admin.id
  end

  let(:userless_token) do
    FactoryBot.create :doorkeeper_access_token,
                       application: application,
                       resource_owner_id: nil
  end

  context "#show" do
    context "caller has an authorization token" do
      it "should return an ok (200) code" do
        api_get api_user_url, user_1_token
        expect(response.code).to eq('200')
        expect(response.body_as_hash).to(
          match Api::V1::UserRepresenter.new(user_1).as_json.deep_symbolize_keys
        )
      end
    end

    context "caller does not have an authorization token" do
      it "should return a forbidden (403) code" do
        api_get api_user_url, nil
        expect(response.code).to eq('403')
      end
    end

    context "caller has an application/client credentials authorization token" do
      it "should return a forbidden (403) code" do
        api_get api_user_url, userless_token
        expect(response.code).to eq('403')
      end
    end
  end

  context "#ui-settings" do
    it "saves to profile" do
      api_put ui_settings_api_user_url, user_1_token, params: {
                previous_ui_settings: {},
                ui_settings: {is_open: false, answer: 42}
              }.to_json
      expect(response.code).to eq('200')
      expect(user_1.reload.ui_settings).to eq({'is_open' => false, 'answer' => 42})
    end
  end


  context '#tour' do
    def record_tour_view_api_user_url(tour_id)
      "/api/user/tours/#{tour_id}"
    end

    it 'records a tour as viewed' do
      expect do
        api_put record_tour_view_api_user_url('the-grand-tour'), user_1_token
        expect(response).to have_http_status(:success)
      end.to change { User::Models::TourView.count }.by(1)
    end
  end
end
