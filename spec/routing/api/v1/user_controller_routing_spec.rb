require "rails_helper"

RSpec.describe Api::V1::UsersController, type: :routing, api: true, version: :v1 do

  context "GET /api/user" do
    it "routes to #show" do
      expect(get '/api/user').to route_to('api/v1/users#show', format: 'json')
    end
  end

end
