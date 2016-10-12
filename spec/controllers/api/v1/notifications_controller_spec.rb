require "rails_helper"

RSpec.describe Api::V1::NotificationsController, type: :controller, api: true, version: :v1 do

  describe "#index" do
    after(:each) do
      Settings::Redis.store.del(Settings::Notifications::KEY)
    end

    it 'returns the contents of Settings::Notifications' do
      1.upto(3){ | num | Settings::Notifications.add("message #{num}") }
      api_get :index, nil
      expect(response.body).to eq(Settings::Notifications.raw)
    end

  end

end
